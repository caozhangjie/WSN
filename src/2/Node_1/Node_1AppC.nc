configuration Node_1AppC {
}
implementation {
  components MainC, LedsC, ActiveMessageC;
  components Node_1C as App;
  components new AMSenderC(AM_NODE_1);
  components new AMReceiverC(AM_NODE_1);
  components SerialActiveMessageC as AM;

  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.Packet -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.AMSend -> AMSenderC;
  App.Receive -> AMReceiverC;
  App.SendSerial -> AM.AMSend[AM_TEST_SERIAL_MSG];
  App.PacketSerial -> AM;
}


