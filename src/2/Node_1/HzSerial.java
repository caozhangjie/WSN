/*									tab:4
 * "Copyright (c) 2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/**
 * Java-side application for testing serial port communication.
 * 
 *
 * @author Phil Levis <pal@cs.berkeley.edu>
 * @date August 12 2005
 */

import java.io.*;
import java.lang.*;

import net.tinyos.tools.*;
import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.awt.font.*;
import java.awt.geom.*;
import java.util.*;

import javax.swing.table.*;
import javax.swing.event.*;


public class HzSerial implements MessageListener {

  private static MoteIF moteIF;
  public HzSerial(MoteIF moteIF){
    this.moteIF = moteIF;
    this.moteIF.registerListener(new HzSerialMsg(16), this);
  }

  public static void sendPackets(int fre) {
    int frequency = fre;
    HzSerialMsg payload = new HzSerialMsg(4);
    try {
	System.out.println("Change frequency " + frequency);
	payload.set_hz(frequency, 32);
	moteIF.send(0, payload);
    }
    catch (IOException exception) {
      System.err.println("Exception thrown when sending packets. Exiting.");
      System.err.println(exception);
    }
  }

  public void messageReceived(int to, Message message) {
    File f = new File("result.txt");
    if (!f.exists()){
        try{
             f.createNewFile();
        }catch (IOException e){
            e.printStackTrace();
        }
    }
    try{
        FileOutputStream os = new FileOutputStream(f, true);
        OutputStreamWriter writer = new OutputStreamWriter(os, "US-ASCII");
        HzSerialMsg msg = (HzSerialMsg)message;
        byte [] buffer = msg.dataGet();
        String data = "" + msg.get_hz(0,32) + " " + msg.get_hz(32,32) + " " + msg.get_hz(64,32) + " " + msg.get_hz(96,32) + "\n";
        System.out.println(data);
        writer.append(data);
        writer.close();
        os.close();
    }catch (IOException e){
    }
  }
  
  private static void usage() {
    System.err.println("usage: HzSerial [-comm <source>]");
  }
  
  public static void main(String[] args) throws Exception {
    System.out.println("test");
    String source = null;
    if (args.length >= 2) {
      if (!args[0].equals("-comm")) {
	usage();
	System.exit(1);
      }
      source = args[1];
    }
    else if (args.length != 0) {
      usage();
      System.exit(1);
    }
    
    PhoenixSource phoenix;
    
    if (source == null) {
      phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
    }
    else {
      phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
    }
    MoteIF mif = new MoteIF(phoenix);
    HzSerial serial = new HzSerial(mif);
    if (args.length > 2){
        serial.sendPackets(Integer.parseInt(args[2]));
    }
  }
 
  	public static void dynamicRun() {
		while (true) {
			try {
				Thread.currentThread().sleep(100);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
		}
	} 

}

