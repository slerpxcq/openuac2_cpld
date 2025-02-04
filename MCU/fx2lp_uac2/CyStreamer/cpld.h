#ifndef _CPLD_H_
#define _CPLD_H_

#include "fx2.h"

#include <stdint.h>

#define CPLD_I2C_ADDR           0x69
#define CPLD_I2S_WORDSIZE_16BIT 0
#define CPLD_I2S_WORDSIZE_32BIT 1
#define CPLD_DSD_DISABLE        0
#define CPLD_DSD_MODE_NATIVE    1

#define TO_CPLD_I2S_WORDSIZE(x) \
    ((x) == 2 ? CPLD_I2S_WORDSIZE_16BIT : \
    (x) == 4 ? CPLD_I2S_WORDSIZE_32BIT : 0)

void CPLD_Init(void);
void CPLD_Enable(void);
void CPLD_Disable(void);
void CPLD_SetClkSrc(void);
void CPLD_ConfigI2S(BYTE wordSize, BYTE clkSrc, BYTE sckDiv, BYTE mckDiv);
void CPLD_ConfigCircBuf(DWORD size);
void CPLD_ConfigDSD(BYTE mode);

#endif // _CPLD_H_