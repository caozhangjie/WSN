#ifndef NODE_1000_H
#define NODE_1000_H

enum {
  AM_NODE_1000 = 6,
};

typedef nx_struct Node_1000Msg {
    nx_uint16_t sequence_number;
    nx_uint32_t random_integer;
} Node_1000Msg;

#endif

