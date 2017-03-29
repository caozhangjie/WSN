#ifndef Node_3_H
#define Node_3_H

#define SIZE 1000
#define MAX_NUM 10000

enum {
  AM_NODE_3 = 6,
};

typedef nx_struct Node_3Msg {
  nx_uint8_t id;
  nx_uint32_t max;
  nx_uint32_t min;
  nx_uint32_t sum;
} Node_3Msg;

#endif

