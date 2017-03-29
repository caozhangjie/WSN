#include "Timer.h" 
#include "stdlib.h"
#include "printf.h"
#include "Node_1000.h"

#define NODEID 1000
#define SIZE 2000
#define MAX_NUM 10000

module Node_1000C  {
    uses {
        interface Boot;
        interface Leds;
        interface Timer<TMilli> as CountTimer;
        interface SplitControl as AMControl;
        interface Packet;
        interface AMSend;
    }
} implementation {
    bool busy = FALSE;
    message_t pkt;
    uint16_t counter = 0;
    uint32_t random_integer;
    Node_1000Msg* btrpkt;
    uint32_t nums[SIZE];
    bool againFlag = FALSE;
    uint16_t i = 0;
    
    void QuickSort(uint16_t l, uint16_t r){
        uint16_t i = l;
        uint16_t j = r;
        uint32_t key;
        if(l >= r) return;
        key = nums[0];
        while(i < j){
            while(i < j && nums[j] >= key) j--;
            nums[i] = nums[j];
            while(i < j && nums[i] <= key) i++;
            nums[j] = nums[i];
        }
        nums[i] = key;
        QuickSort(l, i-1);
        QuickSort(i+1, r);
    }
    
    task void Output(){
        uint32_t max = 0;
        uint32_t min = 10001;
        uint32_t sum = 0;
        uint32_t median = 0;
        uint16_t i = 0;
        call Leds.led2On();
        QuickSort(0, SIZE-1);
        for(i = 0;i < SIZE;i++)
            sum += nums[i];
        call Leds.led2Off();
        max = nums[SIZE-1];min = nums[0];median = (nums[SIZE/2-1]+nums[SIZE/2]) / 2;
        printf("%x\n%x\n%x\n%x\n", max, min, sum, median);
    }
    
    task void SendData(){
        if(busy) return;
        counter = counter % SIZE + 1;
        btrpkt = (Node_1000Msg*)(call Packet.getPayload(&pkt, sizeof(Node_1000Msg)));
        btrpkt->sequence_number = counter;
        btrpkt->random_integer = nums[counter-1];
        if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(Node_1000Msg)) == SUCCESS){
            busy = TRUE;
            call Leds.led0On();
            if(counter == SIZE){
       //         if(!againFlag)
      //              post Output();
                againFlag = TRUE;
                call Leds.led1Toggle();
            }
        }
        else{
            counter--;
            if(counter == 0) counter = SIZE;
        }
    }
    
    event void Boot.booted() {
        srand(0);
        for(i = 0;i < SIZE;i++)
            nums[i] = 2000 - i;
        call AMControl.start();
    }
    
    event void CountTimer.fired() {
        post SendData();
    }
    
    event void AMControl.startDone(error_t err) {
        if (err == SUCCESS)
          call CountTimer.startPeriodic(10);
        else
          call AMControl.start();
    }
    
    event void AMControl.stopDone(error_t err) {
    }

    event void AMSend.sendDone(message_t* msg, error_t error) {
        if (&pkt == msg) {
            busy = FALSE;
            call Leds.led0Off();
        }
    }
}


