#define NEW_PRINTF_SEMANTICS
#include "printf.h"

configuration PrintToRadioAppC {
}
implementation {
  components MainC;
  components LedsC;
  components PrintfC;
  components PrintToRadioC as App;
  components ActiveMessageC;
  components new AMSenderC(AM_PRINTTORADIO);
  components new AMReceiverC(AM_PRINTTORADIO);
  components SerialActiveMessageC as AM; 

  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.PacketWireless -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.SendWireless -> AMSenderC;
  App.ReceiveWireless -> AMReceiverC;
  App.Control -> AM;
  App.ReceiveSerial -> AM.Receive[AM_TEST_SERIAL_MSG];
  App.SendSerial -> AM.AMSend[AM_TEST_SERIAL_MSG];
  App.PacketSerial -> AM;
}

