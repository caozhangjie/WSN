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

import org.jfree.data.time.*;
import org.jfree.chart.*;

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
  public static SerialWindow win;
  private static int col_num = 1;
  private static int row_num = 2;
  private int temperature;
  private int humidity;
  private int photo;
  private int now_time0;
  private int now_time1;
  private int node_id;
  private static double lastValue = 1.0;

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
        Millisecond milli = new Millisecond();
        String data = "" + msg.get_hz(0, 16) + " " + msg.get_hz(32, 16) + " " + msg.get_hz(48, 16) + " " + msg.get_hz(64, 16) + " " + msg.get_hz(80, 16) + " " + msg.get_hz(96, 32) + "\n";
        temperature = msg.get_hz(48, 16);
        humidity = msg.get_hz(64, 16);
        photo = msg.get_hz(80, 16);
        node_id = msg.get_hz(0, 16);
        if (node_id == 0){
            now_time0 = msg.get_hz(96, 32);
            //milli = new Millisecond((now_time0 % 1000), new Second((now_time0 / 1000), new Minute()));
        } 
        else if (node_id == 1){
            now_time1 = msg.get_hz(96, 32); 
           // milli = new Millisecond((now_time1 % 1000), new Second((now_time1 / 1000), new Minute()));
        }
        this.win.update(node_id, milli, temperature, humidity, photo);
        this.win.setLabel(node_id, temperature, humidity, photo);
        if (node_id == 1){
            System.out.println(data);
        }
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
    win.createTimeSeries();
    setWindow();
    MoteIF mif = new MoteIF(phoenix);
    HzSerial serial = new HzSerial(mif);
    if (args.length > 2){
        serial.sendPackets(Integer.parseInt(args[2]));
    }
  }
 
  	public static void dynamicRun() {
		while (true) {
			double factor = 0.90 + 0.2 * Math.random();
			lastValue = lastValue * factor;
			Millisecond now = new Millisecond();
			win.update(0, new Millisecond(), 20, 20, 20);
                        win.update(1, new Millisecond(), 40, 40, 40);
                        win.setLabel(1, 30,30,30);
			try {
				Thread.currentThread().sleep(100);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
		}
	} 

  private static void setWindow(){
    win = new SerialWindow("data", Color.white, 1800, 1200);
    GridLayout layout = new GridLayout(row_num, col_num);
    win.setLayout(layout);
    win.setWindow();
    win.setVisible(true);
  } 
}

class SerialWindow extends JFrame implements ActionListener{
    private static JPanel panel1;
    private JPanel panel2;
    private JLabel temp_label;
    private JLabel hum_label;
    private JLabel photo_label;
    private JLabel tempr_label;
    private JButton set_button;
    private JButton exit_button;
    private JTextField textfield;
    private static TimeSeries timeseries_temp0;
    private static TimeSeries timeseries_temp1;
    private static TimeSeries timeseries_hum0;
    private static TimeSeries timeseries_hum1;  
    private static TimeSeries timeseries_photo0;
    private static TimeSeries timeseries_photo1; 
    private static TimeSeriesCollection timesers_temp; 
    private static TimeSeriesCollection timesers_hum; 
    private static TimeSeriesCollection timesers_photo; 
    private static JFreeChart chart_temp;
    private static JFreeChart chart_hum;
    private static JFreeChart chart_photo;
    

    public SerialWindow(String name, Color c, int w, int h){
        super();
        setTitle(name);
        setSize(w, h);
        Container con = getContentPane();
        con.setBackground(c);
    }
    public void setWindow(){
        panel2 = new JPanel(new GridLayout(3, 3));
        tempr_label = new JLabel("temperature", JLabel.CENTER);
        tempr_label.setFont(new Font(Font.DIALOG, Font.BOLD, 30));
        tempr_label.setBorder(BorderFactory.createLineBorder(Color.black));
        panel2.add(tempr_label);
        tempr_label = new JLabel("humidity", JLabel.CENTER);
        tempr_label.setFont(new Font(Font.DIALOG, Font.BOLD, 30));
        tempr_label.setBorder(BorderFactory.createLineBorder(Color.black));
        panel2.add(tempr_label);
        tempr_label = new JLabel("photo", JLabel.CENTER);
        tempr_label.setFont(new Font(Font.DIALOG, Font.BOLD, 30));
        tempr_label.setBorder(BorderFactory.createLineBorder(Color.black));
        panel2.add(tempr_label);
        temp_label = new JLabel("", JLabel.CENTER);
        temp_label.setFont(new Font(Font.DIALOG, Font.BOLD, 25));
        temp_label.setBorder(BorderFactory.createLineBorder(Color.black));
        panel2.add(temp_label);
        hum_label = new JLabel("", JLabel.CENTER);
        hum_label.setFont(new Font(Font.DIALOG, Font.BOLD, 25));
        hum_label.setBorder(BorderFactory.createLineBorder(Color.black));
        panel2.add(hum_label);
        photo_label = new JLabel("", JLabel.CENTER);
        photo_label.setFont(new Font(Font.DIALOG, Font.BOLD, 25));
        photo_label.setBorder(BorderFactory.createLineBorder(Color.black));
        panel2.add(photo_label);
        set_button = new JButton("set frequency");
        set_button.setFont(new Font(Font.DIALOG, Font.BOLD, 30));
        set_button.addActionListener(this);
        panel2.add(set_button);
        textfield = new JTextField("", 20);
        textfield.setFont(new Font(Font.DIALOG, Font.BOLD, 50));
        panel2.add(textfield);
        exit_button = new JButton("exit");
        exit_button.setFont(new Font(Font.DIALOG, Font.BOLD, 30));
        exit_button.addActionListener(this);
        panel2.add(exit_button);
        this.add(panel1);
        this.add(panel2);
    }
    public void setButton(JButton button){
        button.addActionListener(this);
        this.add(button);
    }
    public void setTextField(JTextField textfield){
        textfield.addActionListener(this);
        this.add(textfield);
    }
    public void actionPerformed(ActionEvent e){
        Container conPane = getContentPane();
        if(e.getActionCommand().equals("set frequency")){
            String s = textfield.getText();
            int fre = Integer.parseInt(s);
            HzSerial.sendPackets(fre);
        }
        else if(e.getActionCommand().equals("exit")){
            System.exit(0);
        }
        else if(e.getSource() == textfield){
            String s = textfield.getText();
            int fre = Integer.parseInt(s);
            HzSerial.sendPackets(fre);
        }
    }
    public static void createTimeSeries(){
        timesers_temp = new TimeSeriesCollection();
        timesers_hum = new TimeSeriesCollection();
        timesers_photo = new TimeSeriesCollection();
        panel1 = new JPanel(new GridLayout(1, 3));

        timeseries_temp0 = new TimeSeries("node0", org.jfree.data.time.Millisecond.class);
        timeseries_temp1 = new TimeSeries("node1", org.jfree.data.time.Millisecond.class);
        timesers_temp.addSeries(timeseries_temp0);
        timesers_temp.addSeries(timeseries_temp1);
        timeseries_hum0 = new TimeSeries("node0", org.jfree.data.time.Millisecond.class);
        timeseries_hum1 = new TimeSeries("node1", org.jfree.data.time.Millisecond.class);
        timesers_hum.addSeries(timeseries_hum0);
        timesers_hum.addSeries(timeseries_hum1);
        timeseries_photo0 = new TimeSeries("node0", org.jfree.data.time.Millisecond.class);
        timeseries_photo1 = new TimeSeries("node1", org.jfree.data.time.Millisecond.class);
        timesers_photo.addSeries(timeseries_photo0);
        timesers_photo.addSeries(timeseries_photo1);
        chart_temp = ChartFactory.createTimeSeriesChart("temperature", "time", "temperature", timesers_temp, true, true, false);
        ChartPanel chartpanel = new ChartPanel(chart_temp);
        panel1.add(chartpanel);
        chart_hum = ChartFactory.createTimeSeriesChart("humidity", "time", "humidity", timesers_hum, true, true, false);
        chartpanel = new ChartPanel(chart_hum);
        panel1.add(chartpanel);
        chart_photo = ChartFactory.createTimeSeriesChart("photo", "time", "photo", timesers_photo, true, true, false);
        chartpanel = new ChartPanel(chart_photo);
        panel1.add(chartpanel);
    }
    public void update(int number, Millisecond time, int temp_value, int hum_value, int photo_value){
        switch(number){
          case 0:
            timeseries_temp0.add(time, temp_value);
            timeseries_hum0.add(time, hum_value);
            timeseries_photo0.add(time, photo_value);
            break;
          case 1:
            timeseries_temp1.add(time, temp_value);
            timeseries_hum1.add(time, hum_value);
            timeseries_photo1.add(time, photo_value);
            break;
        }
    }
    public void setLabel(int node_id, int tem, int hum, int pho){
        temp_label.setText("node_id: " + Integer.toString(node_id) + "   temperature: " + Integer.toString(tem));
        hum_label.setText("node_id: " + Integer.toString(node_id) + "   humidity: " + Integer.toString(hum));
        photo_label.setText("node_id: " + Integer.toString(node_id) + "   photo: " + Integer.toString(pho));
    }
}

