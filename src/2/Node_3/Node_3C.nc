#include "Timer.h"
#include "printf.h"
#include "Node_1000.h"
#include "Node_3.h"
#include "Node_0.h"

#define GROUP_ID 8

module Node_3C  {
    uses {
        interface Boot;
        interface Leds;
        interface SplitControl as AMControl;
        interface Packet;
        interface AMSend;
        interface Receive;
        interface Timer<TMilli> as CountTimer;
    }
} implementation {
    bool busy = FALSE;
    bool succ = FALSE;
    message_t pkt;
    Node_1000Msg* btrpkt;
    Node_3Msg* btrpkt1;
    Node_0Msg* btrpkt2;
    uint16_t i;
    uint32_t nums[SIZE];
    uint32_t left = SIZE;
    uint32_t max = 0;
    uint32_t min = MAX_NUM;
    uint32_t sum = 0;
    uint32_t num;
    uint8_t group_id;
    uint8_t id;
    
    task void SendData(){
        if(succ) return;
        if(busy) return;
        call Leds.led1On();
        btrpkt1 = (Node_3Msg*)(call Packet.getPayload(&pkt, sizeof(Node_3Msg)));
        btrpkt1->id = 3 * GROUP_ID + 2;
        btrpkt1->max = max;
        btrpkt1->min = min;
        btrpkt1->sum = sum;
        if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(Node_3Msg)) == SUCCESS)
            busy = TRUE;
    }
    
    event void Boot.booted() {
        for(i = 0;i < SIZE;i++)
            nums[i] = MAX_NUM + 1;
        call AMControl.start();
    }
    
    event void CountTimer.fired() {
        if(!succ)
            post SendData();
        else   
            call CountTimer.stop();
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
            call Leds.led1Off();
        }
    }

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
        if (len == sizeof(Node_1000Msg)) {
            btrpkt = (Node_1000Msg*)payload;
            if(btrpkt->sequence_number % 2 == 1 && nums[btrpkt->sequence_number / 2] > MAX_NUM){
                num = btrpkt->random_integer;
                nums[btrpkt->sequence_number / 2] = num;
                left--;
                if(num > max) max = num;
                if(num < min) min = num;
                sum += num;
                if(left == 0 && !succ)
                   call CountTimer.startPeriodic(100);
            }
            call Leds.led0Toggle();
        }
        else if(len == sizeof(Node_0Msg)){
            call Leds.led2On();
            btrpkt2 = (Node_0Msg*)payload;
            group_id = btrpkt2->group_id / 3;
            id = btrpkt2->group_id % 3;
            if(group_id == GROUP_ID && id == 2)
                succ = TRUE;
        }
        return msg;
    }

}


