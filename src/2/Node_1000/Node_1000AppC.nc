configuration Node_1000AppC {
}
implementation {
  components MainC, LedsC, ActiveMessageC;
  components Node_1000C as App;
  components new TimerMilliC() as CountTimer;
  components new AMSenderC(AM_NODE_1000);

  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.CountTimer -> CountTimer;
  App.Packet -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.AMSend -> AMSenderC;
}


