configuration Node_3AppC {
}
implementation {
  components MainC, LedsC, ActiveMessageC;
  components Node_3C as App;
  components new TimerMilliC() as CountTimer;
  components new AMSenderC(AM_NODE_3);
  components new AMReceiverC(AM_NODE_3);

  App.CountTimer -> CountTimer;
  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.Packet -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.AMSend -> AMSenderC;
  App.Receive -> AMReceiverC;
}


