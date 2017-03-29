#define NEW_PRINTF_SEMANTICS

configuration PrintToRadioAppC {
}
implementation {
  components MainC;
  components LedsC;
  components PrintToRadioC as App;
  components new TimerMilliC() as CountTimer;
  components new TimerMilliC() as CountTimer1;
  components ActiveMessageC;
  components new AMSenderC(AM_PRINTTORADIO);
  components new AMReceiverC(AM_PRINTTORADIO);
  components new SensirionSht11C();
  components new HamamatsuS1087ParC(); 

  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.CountTimer -> CountTimer;
  App.CountTimer1 -> CountTimer1;
  App.Packet -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.AMSend -> AMSenderC;
  App.Receive -> AMReceiverC;
  App.readTemp -> SensirionSht11C.Temperature;
  App.readHumidity -> SensirionSht11C.Humidity;
  App.readPhoto -> HamamatsuS1087ParC;
}

