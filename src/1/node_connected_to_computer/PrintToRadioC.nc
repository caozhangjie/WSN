#include <Timer.h> 
#include "printf.h"
#include "PrintToRadio.h"

#define NODEID 2

module PrintToRadioC  {
    uses {
        interface Boot;
        interface Leds;
        interface SplitControl as AMControl;
        interface SplitControl as Control;
        interface Packet as PacketWireless;
        interface AMSend as SendWireless;
        interface Receive as ReceiveWireless;
        interface Receive as ReceiveSerial;
        interface AMSend as SendSerial;
        interface Packet as PacketSerial;
    }
} implementation {
    bool busy = FALSE;
    message_t pkt;
    message_t packet;
    message_t hz_board;
    uint16_t counter = 0;
    
    void setLeds(uint16_t val) {
        if (val & 0x01)
          call Leds.led0On();
        else 
          call Leds.led0Off();
        if (val & 0x02)
          call Leds.led1On();
        else
          call Leds.led1Off();
        if (val & 0x04)
          call Leds.led2On();
        else
          call Leds.led2Off();
    }
    event void Boot.booted() {
        call AMControl.start();
        call Control.start();
    }
    
    event void AMControl.startDone(error_t err) {
        if (err == SUCCESS)
          {}
        else
          call AMControl.start();
    }
    
    event void AMControl.stopDone(error_t err) {
    }

    event void SendWireless.sendDone(message_t* msg, error_t error) {
        if (&pkt == msg || &hz_board == msg) {
            busy = FALSE;
        }
    }

    event message_t* ReceiveWireless.receive(message_t* msg, void* payload, uint8_t len) {
        PrintToRadioMsg* btrpkt = (PrintToRadioMsg*)payload;   
        PrintToRadioMsg* rcm = (PrintToRadioMsg*)call PacketSerial.getPayload(&packet, sizeof(PrintToRadioMsg));
        if (len == sizeof(PrintToRadioMsg)) { 
            if(btrpkt -> nodeid == 1){
                counter ++;
                rcm -> trueid = btrpkt -> trueid;
                rcm -> nodeid = btrpkt -> nodeid;
                rcm -> sequence_number = btrpkt -> sequence_number;
                rcm -> TempData = btrpkt -> TempData;
                rcm -> HumidityData = btrpkt -> HumidityData;
                rcm -> PhotoData = btrpkt -> PhotoData;
                rcm -> now_time = btrpkt -> now_time;
                if (!busy && call SendSerial.send(AM_BROADCAST_ADDR, &packet, sizeof(PrintToRadioMsg)) == SUCCESS) {
	            busy = TRUE;
                }
           }
       }     
       return msg;
}

  event message_t* ReceiveSerial.receive(message_t* msg, 
				   void* payload, uint8_t len) {
      SetFrequencyMsg * rcm1;
      test_serial_msg_t* rcm = (test_serial_msg_t*)payload;
      rcm1 = (SetFrequencyMsg*)call PacketSerial.getPayload(&hz_board, sizeof(SetFrequencyMsg)); 
      rcm1->nodeid = NODEID;
      rcm1->now_time = rcm->hz;
      if (!busy && call SendWireless.send(AM_BROADCAST_ADDR, &hz_board, sizeof(SetFrequencyMsg)) == SUCCESS) {
	busy = TRUE;
      }
       return msg;
}

  event void SendSerial.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      busy = FALSE;
    }
  }

  event void Control.startDone(error_t err) {
    if (err == SUCCESS) {
    }
  }
  event void Control.stopDone(error_t err) {}
}

