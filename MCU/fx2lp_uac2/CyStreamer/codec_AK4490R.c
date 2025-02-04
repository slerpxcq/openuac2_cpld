#include "codec_ak4490r.h"

#include "codec.h"
#include "gpio.h"

#include <stddef.h>
#include <string.h>

#define I2C_POLL_FOR_COMPLETE() while (I2CPckt.status != I2C_IDLE)

static AK4490R_RegisterTypeDef xdata Reg;
static uint8_t xdata TxBuf[sizeof(AK4490R_RegisterTypeDef) + 1];

CODEC_TypeDef code codec =
{
	AK4490R_Init,
	NULL,
    NULL,
    NULL,
	// AK4490R_SetFormat,
    NULL,
	NULL,
	AK4490R_SetMute,
	AK4490R_SetVolume
};

uint8_t AK4490R_Init()
{
    AK4490R_RegisterTypeDef xdata *reg = &TxBuf[1];
    TxBuf[0] = AK4490R_CONTROL1_ADDR;

    CODEC_RST_N_PIN = 1;  
    EZUSB_Delay(2);

	Reg.control1 = AK4490R_ACKS | AK4490R_DIF2 | AK4490R_DIF1 | AK4490R_DIF0 | AK4490R_RSTN;
	Reg.control2 = AK4490R_SD | AK4490R_DEM0;
	Reg.control3 = 0x00;
	Reg.lch_att = 0xFF;
	Reg.rch_att = 0xFF;
	Reg.control4 = AK4490R_INVL;
	Reg.dsd1 = 0x00;
	Reg.control5 = AK4490R_SYNCE;
	Reg.sound_control = 0x00;
	Reg.dsd2 = 0x00;
	Reg.control6 = AK4490R_PW;
	Reg.control7 = 0x00;
	Reg.control8 = AK4490R_ADPE;

    memcpy(&TxBuf[1], &Reg, sizeof(Reg));

    EZUSB_WriteI2C(AK4490R_I2C_ADDR, sizeof(TxBuf), TxBuf);
    I2C_POLL_FOR_COMPLETE();

	return TRUE;
}

uint8_t AK4490R_SetVolume(uint8_t vol)
{
    TxBuf[0] = AK4490R_LCH_ATT_ADDR;

    vol = (vol > 0) ? (vol + 155) : 0;
    Reg.lch_att = Reg.rch_att = vol;

    memcpy(TxBuf + 1, &Reg.lch_att, 2);

    EZUSB_WriteI2C(AK4490R_I2C_ADDR, 3, TxBuf);
    I2C_POLL_FOR_COMPLETE();

	return TRUE;
}

uint8_t AK4490R_SetMute(uint8_t mute)
{
    TxBuf[0] = AK4490R_CONTROL2_ADDR;

    if (mute)
        Reg.control2 |= AK4490R_SMUTE;
    else
        Reg.control2 &= ~AK4490R_SMUTE;

    TxBuf[1] = Reg.control2;

    EZUSB_WriteI2C(AK4490R_I2C_ADDR, 2, TxBuf);
    I2C_POLL_FOR_COMPLETE();

	return TRUE;
}

static void AK4490R_SoftReset(BOOL reset)
{
    TxBuf[0] = AK4490R_CONTROL1_ADDR;
    TxBuf[1] = AK4490R_RSTN & reset;
}

uint8_t AK4490R_SetFormat(uint8_t format)
{
    TxBuf[0] = AK4490R_CONTROL3_ADDR;

    switch (format) {
    case CODEC_FORMAT_PCM:
        Reg.control3 &= ~AK4490R_DP;
        break;
    case CODEC_FORMAT_DSD:
        Reg.control3 |= AK4490R_DP;
        break;
    default:
        return FALSE;
    }

    TxBuf[1] = Reg.control3;

    EZUSB_WriteI2C(AK4490R_I2C_ADDR, 2, TxBuf);
    I2C_POLL_FOR_COMPLETE();

	return TRUE;
}


