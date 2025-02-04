#include "cpld.h"

#include "gpio.h"
#include "fx2.h"

#include <stdint.h>

#define I2C_POLL_FOR_COMPLETE() while (I2CPckt.status != I2C_IDLE)

static BYTE xdata TxBuf[9];

void CPLD_Init(void)
{
	CPLD_RST_N_PIN = 0;
    EZUSB_Delay1ms();
	CPLD_RST_N_PIN = 1;
}

void CPLD_Disable(void)
{
    TxBuf[0] = 0x00; // Addr of ENCTL
    TxBuf[1] = 0x00; // FX2IFEN | I2SEN | BUFEN
    EZUSB_WriteI2C(CPLD_I2C_ADDR, 2, TxBuf);
    I2C_POLL_FOR_COMPLETE();
}

void CPLD_Enable()
{
    TxBuf[0] = 0x00; // Addr of ENCTL
    TxBuf[1] = bmBIT2 | bmBIT1 | bmBIT0; // FX2IFEN | I2SEN | BUFEN
    EZUSB_WriteI2C(CPLD_I2C_ADDR, 2, TxBuf);
    I2C_POLL_FOR_COMPLETE();
}

void CPLD_ConfigI2S(BYTE wordSize, BYTE clkSrc, BYTE sckDiv, BYTE mckDiv)
{
    TxBuf[0] = 0x01; // Addr of I2SCTL
    TxBuf[1] = (wordSize << 7) | (mckDiv << 4) | (clkSrc << 3) | sckDiv; 
    EZUSB_WriteI2C(CPLD_I2C_ADDR, 2, TxBuf);
    I2C_POLL_FOR_COMPLETE();
}

void CPLD_ConfigCircBuf(DWORD size)
{
    TxBuf[0] = 0x02; // Addr of BUFCAP0
    TxBuf[1] = size & 0xFF; // BUFCAP0
    TxBuf[2] = (size >> 8U) & 0xFF; // BUFCAP1
    TxBuf[3] = (size >> 16U) & 0xFF; // BUFCAP2
    EZUSB_WriteI2C(CPLD_I2C_ADDR, 4, TxBuf);
    I2C_POLL_FOR_COMPLETE();
}

void CPLD_ConfigDSD(BYTE mode)
{
    TxBuf[0] = 0x05;
    TxBuf[1] = mode;
    EZUSB_WriteI2C(CPLD_I2C_ADDR, 2, TxBuf);
    I2C_POLL_FOR_COMPLETE();
}