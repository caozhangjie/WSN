#ifndef PRINTTORADIO_H
#define PRINTTORADIO_H

enum {
  AM_PRINTTORADIO = 6,
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

typedef nx_struct SetFrequencyMsg {
    nx_uint16_t nodeid;
    nx_uint32_t now_time;
} SetFrequencyMsg;

#endif
