#include <Timer.h> 
#include "printf.h"
#include "PrintToRadio.h"
#include "SensirionSht11.h"

#define NODEID 1

module PrintToRadioC  {
    uses {
        interface Boot;
        interface Leds;
        interface Timer<TMilli> as CountTimer;
        interface Timer<TMilli> as CountTimer1;
        interface SplitControl as AMControl;
        interface Packet;
        interface AMSend;
        interface Receive;
    }
    uses interface Read<uint16_t> as readTemp;
    uses interface Read<uint16_t> as readHumidity;
    uses interface Read<uint16_t> as readPhoto;
} implementation {
    bool busy = FALSE;
    message_t pkt;
    message_t pkt1;
    uint16_t counter = 0;
    uint16_t TempData;
    uint16_t HumidityData;
    uint16_t PhotoData;
    bool Temp_busy = FALSE;
    bool Humidity_busy = FALSE;
    bool Photo_busy = FALSE;
    
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
    
     event void CountTimer1.fired(){
        PrintToRadioMsg* btrpkt;
        counter ++;
                btrpkt = (PrintToRadioMsg*)(call Packet.getPayload(&pkt, sizeof (PrintToRadioMsg)));
                btrpkt->trueid = NODEID;
                btrpkt->nodeid = NODEID;
                btrpkt->sequence_number = counter;
                btrpkt->TempData = TempData;
                btrpkt->HumidityData = HumidityData;
                btrpkt->PhotoData = PhotoData;
                btrpkt->now_time = call CountTimer1.getNow();
                if (!busy && call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(PrintToRadioMsg)) == SUCCESS) {
                    busy = TRUE;
                }
    }
    
    event void Boot.booted() {
        call AMControl.start();
    }

    event void CountTimer.fired() {
        if(!Temp_busy){
            Temp_busy = TRUE;
            call readTemp.read();
        }
        if(!Humidity_busy){
            Humidity_busy = TRUE;
            call readHumidity.read();
        }
        if(!Photo_busy){
            Photo_busy = TRUE; 
            call readPhoto.read();
        }
    }
    
     event void readTemp.readDone(error_t result, uint16_t val) {

        if (result == SUCCESS){
            TempData = val;
        }
        else{ 
            TempData = 0x1000;
        }
        Temp_busy = FALSE;    
     }

    event void readHumidity.readDone(error_t result, uint16_t val) {

        if (result == SUCCESS){
            HumidityData = val;
        }
        else{
            HumidityData = 0x1000;
        }
        Humidity_busy = FALSE;
    }

    event void readPhoto.readDone(error_t result, uint16_t val) {
        if (result == SUCCESS){
            PhotoData = val;
        }
        else{
            PhotoData = 0x1000;
        }
        Photo_busy = FALSE;
    }

    event void AMControl.startDone(error_t err) {
        if (err == SUCCESS){
          call CountTimer.startPeriodic(100);
          call CountTimer1.startPeriodic(100);
        }
        else
          call AMControl.start();
    }
    
    event void AMControl.stopDone(error_t err) {
    }

    event void AMSend.sendDone(message_t* msg, error_t error) {
        if (&pkt == msg || &pkt1 == msg) {
            busy = FALSE;
        }
    }

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
        uint32_t frequency;
        SetFrequencyMsg* btrpkt;
        PrintToRadioMsg* btrpkt2;
        PrintToRadioMsg* btrpkt1;
        if (len == sizeof(PrintToRadioMsg)) {
            
            btrpkt2 = (PrintToRadioMsg*)payload;
            btrpkt1 = (PrintToRadioMsg*)(call Packet.getPayload(&pkt1, sizeof (PrintToRadioMsg)));
            if (btrpkt2->nodeid == 0) {            
                btrpkt1->trueid = btrpkt2->trueid;
                btrpkt1->nodeid = NODEID;
                btrpkt1->sequence_number = btrpkt2->sequence_number;
                btrpkt1->TempData = btrpkt2->TempData;
                btrpkt1->HumidityData = btrpkt2->HumidityData;
                btrpkt1->PhotoData = btrpkt2->PhotoData;
                btrpkt1->now_time = btrpkt2->now_time;
                if (!busy && call AMSend.send(AM_BROADCAST_ADDR, &pkt1, sizeof(PrintToRadioMsg)) == SUCCESS) {
                    busy = TRUE;
                }
            }
       }
       else if (len == sizeof(SetFrequencyMsg)){          
            btrpkt = (SetFrequencyMsg*)payload;
            if (btrpkt->nodeid == 2) {  
                setLeds(1);          
                frequency = btrpkt->now_time;
                call CountTimer.startPeriodic(frequency);
                call CountTimer1.startPeriodic(frequency);
            }
        }       
        return msg;
    }

}

