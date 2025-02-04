#ifndef _CODEC_H_
#define _CODEC_H_

#include "fx2.h"

#include <stdint.h>

typedef enum 
{
	CODEC_FORMAT_PCM,
	CODEC_FORMAT_DSD
} CODEC_FormatTypeDef;

typedef struct
{
	uint8_t (*Init)(void);
	uint8_t (*DeInit)(void);
	uint8_t (*Play)(void);
	uint8_t (*Stop)(void);
	uint8_t (*SetFormat)(uint8_t);
	uint8_t (*SetFreq)(uint32_t);
	uint8_t (*SetMute)(uint8_t);
	uint8_t (*SetVolume)(uint8_t);
} CODEC_TypeDef;

extern CODEC_TypeDef code codec;

#endif // _CODEC_H_