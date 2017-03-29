#ifndef Node_0_H
#define Node_0_H

enum {
  AM_NODE_0 = 6,
  AM_TEST_SERIAL_MSG = 0x89,
};

typedef nx_struct Node_0Msg {
  nx_uint8_t group_id;
} Node_0Msg;

typedef nx_struct tmpMsg {
  nx_uint32_t max;
  nx_uint32_t min;
  nx_uint32_t sum;
  nx_uint32_t median;
} tmpMsg;

#endif

