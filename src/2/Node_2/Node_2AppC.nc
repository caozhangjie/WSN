configuration Node_2AppC {
}
implementation {
  components MainC, LedsC, ActiveMessageC;
  components Node_2C as App;
  components new TimerMilliC() as CountTimer;
  components new AMSenderC(AM_NODE_3);
  components new AMReceiverC(AM_NODE_3);
  components SerialActiveMessageC as AM;

  App.CountTimer -> CountTimer;
  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.Packet -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.AMSend -> AMSenderC;
  App.Receive -> AMReceiverC;
  App.SendSerial -> AM.AMSend[AM_TEST_SERIAL_MSG];
  App.PacketSerial -> AM;
}


