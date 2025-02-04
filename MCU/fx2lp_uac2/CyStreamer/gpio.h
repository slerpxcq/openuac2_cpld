#ifndef _GPIO_H_
#define _GPIO_H_

#include "fx2regs.h"

sbit CPLD_RST_N_PIN = IOA ^ 0;
sbit FB_REQ_PIN     = IOA ^ 7;
sbit CODEC_RST_N_PIN = IOA ^ 6;

#endif // _GPIO_H_