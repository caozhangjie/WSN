#include "Timer.h"
#include "printf.h"
#include "Node_1000.h"
#include "Node_0.h"
#include "Node_3.h"
#include "Node_1.h"

#define GROUP_ID 8

module Node_1C  {
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
    bool flag[2*SIZE];
    bool node_0 = FALSE;
    bool node_2 = TRUE;
    bool node_3 = TRUE;
    message_t pkt;
    message_t packet;
    Node_1000Msg* btrpkt;
    Node_3Msg* btrpkt1;
    Node_0Msg* btrpkt2;
    Node_1Msg* btrpkt3;
    tmpMsg* bt;
    uint32_t max = 0;
    uint32_t min = MAX_NUM;
    uint32_t sum = 0;
    uint32_t nums[SIZE + 5];
    uint32_t ld = 0;
    uint32_t i = 0;
    uint32_t left = 2 * SIZE;
    uint8_t group_id;
    uint8_t id;
    uint8_t ack_stack[2];
    
    task void SendData(){
        if(node_0) return;
        if(busy){
            post SendData();
            return;
        }
        call Leds.led2On();
        btrpkt3 = (Node_1Msg*)(call Packet.getPayload(&pkt, sizeof(Node_1Msg)));
        btrpkt3->group_id = GROUP_ID;
        btrpkt3->max = max;
        btrpkt3->min = min;
        btrpkt3->sum = sum;
        btrpkt3->average = sum / (2 * SIZE);
        btrpkt3->median = (nums[SIZE-1] + nums[SIZE]) / 2;
   //     bt = (tmpMsg*)(call Packet.getPayload(&packet, sizeof(tmpMsg)));
   //     bt->max = max;bt->min=min;bt->sum=nums[SIZE-1];bt->median=nums[SIZE];
   //     if(!busy && call SendSerial.send(AM_BROADCAST_ADDR, &packet, sizeof(tmpMsg)) == SUCCESS) busy = TRUE;
        if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(Node_1Msg)) == SUCCESS)
            busy = TRUE;
        else    
            post SendData();
    }
    
    void HalfInsertSort(uint32_t num){
        uint32_t l, r, mid, tmp;
        l = 0;
        r = ld;
        tmp = l;
        while(l < r){
            mid = (l + r) / 2;
            if(nums[mid] == num){
                l = mid;
                r = l;
            }
            else if(num < nums[mid])
                r = mid;
            else
                l = mid + 1;
        }
        for(i = ld;i > l;i--){
            nums[i] = nums[i-1];
        }
        nums[l] = num;
        sum += num;
        if(num > max) max = num;
        if(num < min) min = num;
        ld++;
        if(ld > SIZE + 2) ld = SIZE + 2;
        left--;
  //      bt = (tmpMsg*)(call PacketSerial.getPayload(&packet,sizeof(tmpMsg)));
  //      bt->max = l;bt->min = num;bt->sum = nums[0];bt->median = left;
  //      if(!busy && call SendSerial.send(AM_BROADCAST_ADDR, &packet, sizeof(tmpMsg)) == SUCCESS) busy = TRUE;
        if(left == 0 && node_2 && node_3)
            post SendData();
    }
    
    task void SendACK(){
        if(busy){
            post SendACK();
            return;
        }
        btrpkt2 = (Node_0Msg*)(call Packet.getPayload(&pkt, sizeof(Node_0Msg)));
        ack_stack[0]--;
        btrpkt2->group_id = 3 * GROUP_ID + ack_stack[ack_stack[0]];
        if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(Node_0Msg)) == SUCCESS)
            busy = TRUE;
        else    
            post SendACK();
    }
    
    void UpdateData(Node_3Msg* btr, uint8_t type){
  //      bt = (tmpMsg*)(call PacketSerial.getPayload(&packet, sizeof(tmpMsg)));
  //      bt->max = btr->max;bt->min=btr->min;bt->sum=btr->sum;bt->median=0;
  //      if(call SendSerial.send(AM_BROADCAST_ADDR, &packet, sizeof(tmpMsg)) == SUCCESS) busy = TRUE;
        if(btr->max > max)
            max = btr->max;
        if(btr->min < min)
            min = btr->min;
        sum += btr->sum;
        if(type == 2)
            node_2 = TRUE;
        else if(type == 3)
            node_3 = TRUE;
        if(left == 0 && node_2 && node_3)
            post SendData();
    }
    
    event void Boot.booted() {
        ack_stack[0] = 0;
        for(i = 0;i < SIZE + 5;i++)
            nums[i] = MAX_NUM + 1;
        for(i = 0;i < 2 * SIZE;i++)
            flag[i] = FALSE;
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
            if(!node_0 && left == 0 && node_2 && node_3)
                post SendData();
        }
    }

    event void SendSerial.sendDone(message_t* msg, error_t error){
       if(&packet == msg) busy = FALSE;
    }

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
        if (len == sizeof(Node_1000Msg)) {
            call Leds.led0Toggle();
            btrpkt = (Node_1000Msg*)payload;
            if(!flag[btrpkt->sequence_number-1]){
                flag[btrpkt->sequence_number-1] = TRUE;
                HalfInsertSort(btrpkt->random_integer);
            }
        }
/*
        else if(len == sizeof(Node_3Msg)) {
            call Leds.led1Toggle();
            btrpkt1 = (Node_3Msg*)payload;
            group_id = btrpkt1->id / 3;
            id = btrpkt1->id % 3;
            if(group_id == GROUP_ID){
                if(id == 1 && !node_2){
                    node_2 = TRUE;
                    UpdateData(btrpkt1, 2);
                }
                else if(id == 2 && !node_3){
                    node_3 = TRUE;
                    UpdateData(btrpkt1, 3);
                }
                ack_stack[ack_stack[0]] = id;
                ack_stack[0]++;
                post SendACK();
            }
        }
*/
        else if(len == sizeof(Node_0Msg)) {
            call Leds.led2Off();
            btrpkt2 = (Node_0Msg*)payload;
            if(btrpkt2->group_id == GROUP_ID)
                node_0 = TRUE;
        }   
        return msg;
    }
}


