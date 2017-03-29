#include "Timer.h"
#include "printf.h"
#include "Node_1.h"
#include "Node_0.h"

#define NODEID 0

module Node_0C  {
    uses {
        interface Boot;
        interface Leds;
        interface SplitControl as AMControl;
        interface Packet;
        interface AMSend;
        interface Receive;
        interface AMSend as SendSerial;
        interface Packet as PacketSerial;
    }
} implementation {
    bool busy = FALSE;
    message_t pkt;
    message_t packet;
    Node_1Msg* btrpkt;
    Node_0Msg* btrpkt1;
    tmpMsg* btr;
    
    task void SendData(){
        if(busy){
            post SendData();
            return;
        }
        call Leds.led0On();
        btrpkt1 = (Node_0Msg*)(call Packet.getPayload(&pkt, sizeof(Node_0Msg)));
        btrpkt1->group_id = btrpkt->group_id;
        if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(Node_0Msg)) == SUCCESS)
            busy = TRUE;
    }
    
    event void Boot.booted() {
        call AMControl.start();
    }
    
    event void AMControl.startDone(error_t err) {
        if (err != SUCCESS)
          call AMControl.start();
    }
    
    event void AMControl.stopDone(error_t err) {
    }

    event void AMSend.sendDone(message_t* msg, error_t error) {
        if(&pkt == msg){
            busy = FALSE;
            call Leds.led0Off();
        }
    }
    
    event void SendSerial.sendDone(message_t* msg, error_t error) {
        if(&packet == msg) busy = FALSE;
    }

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
        btrpkt = (Node_1Msg*)payload;
        if (len == sizeof(Node_1Msg)){
            call Leds.led1Toggle();
            btr = (tmpMsg*)(call PacketSerial.getPayload(&packet, sizeof(tmpMsg)));
            btr->max=btrpkt->max;btr->min=btrpkt->min;btr->sum=btrpkt->sum;btr->median=btrpkt->median;
            if(!busy && SendSerial.send(AM_BROADCAST_ADDR, &packet, sizeof(tmpMsg)) == SUCCESS) busy = TRUE;
            post SendData();
        }
        return msg;
    }

}


