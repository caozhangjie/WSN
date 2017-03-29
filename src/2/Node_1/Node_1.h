#ifndef Node_1_H
#define Node_1_H

enum {
  AM_NODE_1 = 0,
};

typedef nx_struct Node_1Msg {
  nx_uint8_t group_id;
  nx_uint32_t max;
  nx_uint32_t min;
  nx_uint32_t sum;
  nx_uint32_t average;
  nx_uint32_t median;
} Node_1Msg;

#endif

