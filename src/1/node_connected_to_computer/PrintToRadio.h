#ifndef PRINTTORADIO_H
#define PRINTTORADIO_H

enum {
  AM_PRINTTORADIO = 6,
  AM_TEST_SERIAL_MSG = 0x89,
};

typedef nx_struct PrintToRadioMsg {
    nx_uint16_t trueid;
    nx_uint16_t nodeid;
    nx_uint16_t sequence_number;
    nx_uint16_t TempData;
    nx_uint16_t HumidityData;
    nx_uint16_t PhotoData;
    nx_uint32_t now_time;
} PrintToRadioMsg;

typedef nx_struct test_serial_msg {
  nx_uint32_t hz;
} test_serial_msg_t;

typedef nx_struct SetFrequencyMsg {
    nx_uint16_t nodeid;
    nx_uint32_t now_time;
} SetFrequencyMsg;

#endif
