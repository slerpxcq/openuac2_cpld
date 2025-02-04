#pragma NOIV // Do not generate interrupt vectors
//-----------------------------------------------------------------------------
//   File:      CYStream.c
//   Contents:   USB Bulk and Isoc streaming example code.
//
// Copyright (c) 2011, Cypress Semiconductor Corporation All rights reserved
//
// This software is owned by Cypress Semiconductor Corporation
// (Cypress) and is protected by United States copyright laws and
// international treaty provisions.  Therefore, unless otherwise specified in a
// separate license agreement, you must treat this
// software like any other copyrighted material.  Reproduction, modification, translation,
// compilation, or representation of this software in any other form
// (e.g., paper, magnetic, optical, silicon, etc.) is prohibited
// without the express written permission of Cypress.
//
// Disclaimer: Cypress makes no warranty of any kind, express or implied, with
// regard to this material, including, but not limited to, the implied warranties
// of merchantability and fitness for a particular purpose. Cypress reserves the
// right to make changes without further notice to the materials described
// herein. Cypress does not assume any liability arising out of the application
// or use of any product or circuit described herein. Cypress� products described
// herein are not authorized for use as components in life-support devices.
//
// This software is protected by and subject to worldwide patent
// coverage, including U.S. and foreign patents. Use may be limited by
// and subject to the Cypress Software License Agreement.
//
//-----------------------------------------------------------------------------
#include "fx2.h"
#include "fx2regs.h"
#include "fx2sdly.h" 

#include "uac2.h"

#include "gpio.h"
#include "cpld.h"
#include "codec.h"

#include <stddef.h>
#include <stdint.h>

#define WRITE_PACKED(ptr, type, val) \
	*(type *)(ptr) = (val);          \
	(ptr) += sizeof(type)

#define SWAP_ENDIAN_DWORD(x) (((x) >> 24) | (((x) & 0xff0000) >> 8) | (((x) & 0xff00) << 8) | ((x) << 24))
#define SWAP_ENDIAN_WORD(x) (((x) >> 8) | ((x) << 8))

#define MAX(x, y) ((x) > (y) ? (x) : (y))
#define MIN(x, y) ((x) < (y) ? (x) : (y))
#define CLAMP(x, lo, hi) ((x) > (hi) ? (hi) : (x) < (lo) ? (lo) : (x))
#define LOG2(x) \
	((x) >= (1L << 7) ? 7 : \
	(x) >= (1L << 6) ? 6 : \
	(x) >= (1L << 5) ? 5 : \
	(x) >= (1L << 4) ? 4 : \
	(x) >= (1L << 3) ? 3 : \
	(x) >= (1L << 2) ? 2 : \
	(x) >= (1L << 1) ? 1 : 0)

#define FEEDBACK_MAX_COUNT 30000L // 30MHz(ifclk) / 1kHz(sof/interval)
#define FEEDBACK_LIMIT 16L
#define FEEDBACK_VAL_48K  393216L
#define FEEDBACK_VAL_44K1 361267L 
#define FEEDBACK_INTERVAL 8U // Interval for feedback request in number of SOFs

#define FOSC_48K  98304000L
#define FOSC_44K1 90316800L

#define ARM_EP2() \
	EP2FIFOCFG = 0x01; \
	SYNCDELAY; \
	EP2FIFOCFG = 0x11; \
	SYNCDELAY; 

typedef struct 
{
	BYTE cmd;
	BYTE len;
	BYTE unit;
} AUDIOCONTROLDATA;

typedef enum 
{
	STREAM_TYPE_PCM,
	STREAM_TYPE_DSD
} STREAMTYPE;

// MCK divider table, index is LOG2(SCK divider) 
BYTE code MckDivTable[8] =
{
	2,  // 1536k, 1141k -> 24.576M/22.5792M
	2,  // 768k,705k -> 24.576M/22.5792M
	2,  // 384k, 352k -> 24.576M/22.5792M
	2,  // 192k, 176k -> 24.576M/22.5792M
	2,  // 96k, 88k -> 24.576M/22.5792M
	3,  // 48k, 44k -> 12.288M/11.2896M
	3, 
	3, 
};

extern BOOL GotSUD; // Received setup data flag
extern BOOL Sleep;
extern BOOL Rwuen;
extern BOOL Selfpwr;

static AUDIOCONTROLDATA AudioControlData;

static BYTE Configuration;	         // Current configuration
static BYTE AlternateSetting;        // Alternate settings; controls word size

static int32_t WordSize = 2;         // Audio word size (in bytes)
static int32_t FreqMultiplier;       // Multiplier of base frequency (44K1 or 48K)
static int32_t FeedbackValBase;      // Feedback base value, equal to FEEDBACK_VAL_{44K1|48K} * FreqMultiplier
static int32_t FeedbackValue;
static int32_t BufPacketCount = 200; // Packet count in buffer; max required memory is 200 * 1536B / 1024 = 300KB
static int32_t BufCap;               // Circular buffer capacity in words
static int32_t PacketSize;           // Packet size in bytes
static int32_t Freq = 44100;         // Sampling frequency
static BYTE StreamType = STREAM_TYPE_PCM;

static BYTE Volume = 0;
static BYTE Mute = 0;

// Volatile flags that are set in ISRs
volatile BOOL GotFeedbackValue = FALSE; // CPLD sends feedback value and sets this flag in ISR_INT1
volatile BOOL GotEP0Data = FALSE;       // Got AudioControl data in EP0

//-----------------------------------------------------------------------------
// Feedback handling
// CPLD send the current buffer size to IN Endpoint (EP8). The feedback value is
// calculated then commited.
// 
// The compiler could not handle shifting of 32 bit numbers properly, use division 
// instead.
//-----------------------------------------------------------------------------

static void SendFeedbackValue(void)
{
	DWORD feedbackVal; 
	WORD count;
	int32_t diff;
	int32_t limit;

	count = *(WORD xdata *)EP8FIFOBUF;
	SYNCDELAY;

	diff = (int32_t)count - (FEEDBACK_MAX_COUNT / 2);
	limit = FEEDBACK_LIMIT * FreqMultiplier;
	diff = CLAMP(diff, -limit, limit);
	feedbackVal = FeedbackValBase - diff;

	EP8FIFOBUF[0] = ((BYTE *)&feedbackVal)[3];
	EP8FIFOBUF[1] = ((BYTE *)&feedbackVal)[2];
	EP8FIFOBUF[2] = ((BYTE *)&feedbackVal)[1];
	EP8FIFOBUF[3] = ((BYTE *)&feedbackVal)[0];
	SYNCDELAY;

	EP8BCH = 0x00;
	SYNCDELAY;
	EP8BCL = 0x04;
	SYNCDELAY;
	INPKTEND = 0x08;
}

//-----------------------------------------------------------------------------
// Init functions
//-----------------------------------------------------------------------------

static void GPIO_Init(void)
{
	// PA0 output
	CPLD_RST_N_PIN = 0;
	OEA |= bmBIT0;

	// PA7 output
	FB_REQ_PIN = 0;
	OEA |= bmBIT7;

	// PA6 output
	CODEC_RST_N_PIN = 0;
	OEA |= bmBIT6;

	// PA1 INT1 input
	PORTACFG |= bmBIT1;
	SYNCDELAY;
}

static void NVIC_Init(void)
{
	// Enable INT1
	IT1 = 1;
	EX1 = 1;
}

static void Flags_Init(void)
{
	// FLAGC -> EP2 EF
	PINFLAGSCD &= 0xF0;
	SYNCDELAY;
	PINFLAGSCD |= 0x08;
	SYNCDELAY;
}

static void EP_Init(void)
{
	// REVCTL = 0x03;
	// SYNCDELAY;
	// Close unused EPs
	EP1OUTCFG &= 0x7F;
	SYNCDELAY;
	EP1INCFG &= 0x7F;
	SYNCDELAY;
	EP4CFG &= 0x7F;
	SYNCDELAY;
	EP6CFG &= 0x7F;
	SYNCDELAY;

	// EP2: OUT, ISOC, 1024, 3x
	EP2CFG = 0x9F;
	SYNCDELAY;
	// EP8: IN, ISOC, 512, 2x
	EP8CFG = 0xD2;
	SYNCDELAY;
}

static void FIFO_Init(void)
{
	// Reset FIFOs
	FIFORESET = 0x80;
	SYNCDELAY;
	FIFORESET = 0x02;
	SYNCDELAY;
	FIFORESET = 0x04;
	SYNCDELAY;
	FIFORESET = 0x06;
	SYNCDELAY;
	FIFORESET = 0x08;
	SYNCDELAY;
	FIFORESET = 0x00;
	SYNCDELAY;

	// EP2: AUTOOUT=0, WORDWIDE=1
	EP2FIFOCFG = 0x01;
	SYNCDELAY;

	// EP8: AUTOIN=0, WORDWIDE=1
	EP8FIFOCFG = 0x01;
	SYNCDELAY;
}

// Return TRUE when success
static BOOL SetFreqWordSize(void)
{
	BYTE sckDiv = 0;
	BOOL isMultipleOf48K = FALSE;
	BOOL isMultipleOf44K1 = FALSE;

	// Close EPs
	EP2CFG &= ~(bmBIT7);
	SYNCDELAY;
	EP8CFG &= ~(bmBIT7);
	SYNCDELAY;

	// Reset FIFOs
	FIFORESET = 0x82;
	SYNCDELAY;
	FIFORESET = 0x88;
	SYNCDELAY;
	FIFORESET = 0x00;
	SYNCDELAY;

	// Reset CPLD
	CPLD_Init();

	isMultipleOf48K = (Freq % 48000 == 0); 
	isMultipleOf44K1 = (Freq % 44100 == 0);
	if (isMultipleOf48K) {
		FreqMultiplier = Freq / 48000;
		FeedbackValBase = FEEDBACK_VAL_48K * FreqMultiplier;
		sckDiv = LOG2(FOSC_48K / (Freq * WordSize * 16));
		CPLD_ConfigI2S(TO_CPLD_I2S_WORDSIZE(WordSize), isMultipleOf48K, sckDiv, MckDivTable[sckDiv]);
	} else if (isMultipleOf44K1) {
		FreqMultiplier = Freq / 44100;
		FeedbackValBase = FEEDBACK_VAL_44K1 * FreqMultiplier;
		sckDiv = LOG2(FOSC_44K1 / (Freq * WordSize * 16));
		CPLD_ConfigI2S(TO_CPLD_I2S_WORDSIZE(WordSize), isMultipleOf48K, sckDiv, MckDivTable[sckDiv]);
	} else {
		return FALSE;
	} 
	PacketSize = (WordSize == 4) ? (Freq / 1000) : (Freq / 2000);
	BufCap = BufPacketCount * (PacketSize / 2); // Div by 2 because BufCap unit is in WORD

	CPLD_ConfigCircBuf(BufCap);
	CPLD_Enable();

	// Open EPs
	EP2CFG |= bmBIT7;
	SYNCDELAY;
	EP8CFG |= bmBIT7;
	SYNCDELAY;

	ARM_EP2();

	return TRUE;
}

static void SetStreamType(void)
{
	switch (StreamType) {
	case STREAM_TYPE_PCM:
		CPLD_ConfigDSD(CPLD_DSD_DISABLE);
		if (codec.SetFormat)
			codec.SetFormat(CODEC_FORMAT_PCM);
		break;
	case STREAM_TYPE_DSD:
		CPLD_ConfigDSD(CPLD_DSD_MODE_NATIVE);
		if (codec.SetFormat)
			codec.SetFormat(CODEC_FORMAT_DSD);
		break;
	}
}

//-----------------------------------------------------------------------------
// Task Dispatcher hooks
// The following hooks are called by the task dispatcher.
//-----------------------------------------------------------------------------

void TD_Init(void) // Called once at startup
{
	// CPU clock 48MHz
	CPUCS = ((CPUCS & ~bmCLKSPD) | bmCLKSPD1);
	SYNCDELAY;

	NVIC_Init();
	GPIO_Init();
	Flags_Init();

	// Slave FIFO, internal 30MHz clock output
	IFCONFIG = 0xA3;
	SYNCDELAY;

	EP_Init();
	FIFO_Init();

	// We want to get SOF interrupts
	USBIE |= bmSOF;
	Rwuen = TRUE; // Enable remote-wakeup

	CPLD_Init();
}

void TD_InitAfterI2C(void)
{
	if (codec.Init)
		codec.Init();
}

void TD_Poll(void) // Called repeatedly while the device is idle
{
	if (USBERRIRQ & bmBIT4) {
		// Reset FIFOs
		FIFORESET = 0x82;
		SYNCDELAY;
		FIFORESET = 0x00;
		SYNCDELAY;

		ARM_EP2();

		USBERRIRQ = bmBIT4;
	}

	if (GotFeedbackValue) {
		SendFeedbackValue();
		GotFeedbackValue = FALSE;
	}

	if (GotEP0Data) {
		switch (AudioControlData.unit) {
		case CLOCK_SOURCE_ID:
			switch (AudioControlData.cmd) {
			case CS_SAM_FREQ_CONTROL:
				((BYTE *)&Freq)[3] = EP0BUF[0];
				((BYTE *)&Freq)[2] = EP0BUF[1];
				((BYTE *)&Freq)[1] = EP0BUF[2];
				((BYTE *)&Freq)[0] = EP0BUF[3];
				if (!SetFreqWordSize()) {
					EZUSB_STALL_EP0();
				}
				break;
			default:
				EZUSB_STALL_EP0();
				break;
			}
			break;
		case FEATURE_UNIT_ID:
		 	switch (AudioControlData.cmd) {
		 	case FU_MUTE_CONTROL:
		 		Mute = EP0BUF[0];
		 		if (codec.SetMute) {
		 			codec.SetMute(Mute);
				}
		 		break;
		 	case FU_VOLUME_CONTROL:
		 		Volume = EP0BUF[0];
		 		if (codec.SetVolume) {
		 			codec.SetVolume(Volume);
				}
		 		break;
		 	default:
		 		EZUSB_STALL_EP0();
				break;
		 	}
		 	break;
		default:
			EZUSB_STALL_EP0();
			break;
		}

		GotEP0Data = FALSE;
	}
}

BOOL TD_Suspend(void) // Called before the device goes into suspend mode
{
	return (TRUE);
}

BOOL TD_Resume(void) // Called after the device resumes
{
	return (TRUE);
}

//-----------------------------------------------------------------------------
// Device Request hooks
//   The following hooks are called by the end point 0 device request parser.
//-----------------------------------------------------------------------------

// Audio requests
BOOL DR_GetCur(void)
{
	BYTE cmd = SETUPDAT[3];
	BYTE unit = SETUPDAT[5];

	switch (unit) {
	case CLOCK_SOURCE_ID:
		switch (cmd) {
		case CS_SAM_FREQ_CONTROL:
			EP0BUF[0] = ((BYTE *)&Freq)[3]; // Endianess problem
			EP0BUF[1] = ((BYTE *)&Freq)[2];
			EP0BUF[2] = ((BYTE *)&Freq)[1];
			EP0BUF[3] = ((BYTE *)&Freq)[0];
			break;
		default:
			EZUSB_STALL_EP0();
			break;
		}
		break;
	case FEATURE_UNIT_ID:
		switch (cmd) {
		case FU_MUTE_CONTROL:
			EP0BUF[0] = Mute;
			EP0BUF[1] = 0;
			EP0BUF[2] = 0;
			EP0BUF[3] = 0;
			break;
		case FU_VOLUME_CONTROL:
			EP0BUF[0] = Volume;
			EP0BUF[1] = 0;
			EP0BUF[2] = 0;
			EP0BUF[3] = 0;
			break;
		default:
			EZUSB_STALL_EP0();
			break;
		}
		break;
	default:
		EZUSB_STALL_EP0();
		break;
	}

	EP0BCH = 0;
	EP0BCL = SETUPDAT[6];
	return TRUE;
}

BOOL DR_SetCur(void)
{
	if (SETUPDAT[6] != 0) {
		AudioControlData.cmd = SETUPDAT[3];
		AudioControlData.unit = SETUPDAT[5];
		AudioControlData.len = SETUPDAT[6];
	}

	// Prepare recieve; MUST NOT BE OMITTED
	EP0BCL = 0;
	return TRUE;
}

BOOL DR_GetRange(void)
{
	BYTE xdata *wrPtr = EP0BUF;
	BYTE cmd = SETUPDAT[3];
	BYTE unit = SETUPDAT[5];

	switch (unit) {
	case CLOCK_SOURCE_ID:
		switch (cmd) {
		case CS_SAM_FREQ_CONTROL:
			WRITE_PACKED(wrPtr, WORD,  SWAP_ENDIAN_WORD((WORD)1UL));        
			WRITE_PACKED(wrPtr, DWORD, SWAP_ENDIAN_DWORD((DWORD)CS_MIN_FREQ));  
			WRITE_PACKED(wrPtr, DWORD, SWAP_ENDIAN_DWORD((DWORD)CS_MAX_FREQ)); 
			WRITE_PACKED(wrPtr, DWORD, SWAP_ENDIAN_DWORD((DWORD)CS_FREQ_STEP));      
			EP0BCH = 0;
			EP0BCL = wrPtr - EP0BUF;
			break;
		default:
			EZUSB_STALL_EP0();
			break;
		}
		break;
	case FEATURE_UNIT_ID:
		switch (cmd) {
		case FU_VOLUME_CONTROL:
			WRITE_PACKED(wrPtr, WORD, SWAP_ENDIAN_WORD((WORD)1UL));   
			WRITE_PACKED(wrPtr, WORD, SWAP_ENDIAN_WORD((WORD)FU_MIN_VOLUME));   
			WRITE_PACKED(wrPtr, WORD, SWAP_ENDIAN_WORD((WORD)FU_MAX_VOLUME)); 
			WRITE_PACKED(wrPtr, WORD, SWAP_ENDIAN_WORD((WORD)FU_VOLUME_STEP));   
			EP0BCH = 0;
			EP0BCL = wrPtr - EP0BUF;
		default:
			EZUSB_STALL_EP0();
			break;
		}
		break;
	default:
		EZUSB_STALL_EP0();
		break;
	}

	return TRUE;
}

BOOL DR_GetDescriptor(void)
{
	return (TRUE);
}

BOOL DR_SetConfiguration(void) // Called when a Set Configuration command is received
{
	Configuration = SETUPDAT[2];
	return (TRUE); // Handled by user code
}

BOOL DR_GetConfiguration(void) // Called when a Get Configuration command is received
{
	EP0BUF[0] = Configuration;
	EP0BCH = 0;
	EP0BCL = 1;
	return (TRUE); // Handled by user code
}

BOOL DR_SetInterface(void) // Called when a Set Interface command is received
{
	AlternateSetting = SETUPDAT[2];

	switch (AlternateSetting) {
	case 1: case 2: case 4:
		WordSize = 4; 
		break;
	case 3: 
		WordSize = 2; 
		break;
	}

	switch (AlternateSetting) {
	case 1: case 2: case 3:
		StreamType = STREAM_TYPE_PCM;
		break;
	case 4:
		StreamType = STREAM_TYPE_DSD;
		break;
	}

	if (AlternateSetting > 0) {
		if (!SetFreqWordSize()) 
			EZUSB_STALL_EP0();
		else 
			SetStreamType();
	}

	return TRUE; 
}

BOOL DR_GetInterface(void) // Called when a Set Interface command is received
{
	EP0BUF[0] = AlternateSetting;
	EP0BCH = 0;
	EP0BCL = 1;
	return (TRUE); // Handled by user code
}

BOOL DR_GetStatus(void)
{
	return (TRUE);
}

BOOL DR_ClearFeature(void)
{
	return (TRUE);
}

BOOL DR_SetFeature(void)
{
	return (TRUE);
}

BOOL DR_VendorCmnd(void)
{
	return (TRUE);
}

//-----------------------------------------------------------------------------
// USB Interrupt Handlers
// The following functions are called by the USB interrupt jump table.
//-----------------------------------------------------------------------------

// Setup Data Available Interrupt Handler
void ISR_Sudav(void) interrupt 0
{
	GotSUD = TRUE; // Set flag
	EZUSB_IRQ_CLEAR();
	USBIRQ = bmSUDAV; // Clear SUDAV IRQ
}

// Setup Token Interrupt Handler
void ISR_Sutok(void) interrupt 0
{
	EZUSB_IRQ_CLEAR();
	USBIRQ = bmSUTOK; // Clear SUTOK IRQ
}

void ISR_Sof(void) interrupt 0
{
	static BYTE sofCount;

	if (++sofCount == FEEDBACK_INTERVAL) {
		sofCount = 0;
		FB_REQ_PIN ^= 1;
	}

	EZUSB_IRQ_CLEAR();
	USBIRQ = bmSOF; // Clear SOF IRQ
}

void ISR_Ures(void) interrupt 0
{
	// Whenever we get a USB Reset, we should revert to full speed mode
	pConfigDscr = pFullSpeedConfigDscr;
	((CONFIGDSCR xdata *)pConfigDscr)->type = CONFIG_DSCR;
	pOtherConfigDscr = pHighSpeedConfigDscr;
	((CONFIGDSCR xdata *)pOtherConfigDscr)->type = OTHERSPEED_DSCR;

	EZUSB_IRQ_CLEAR();
	USBIRQ = bmURES; // Clear URES IRQ
}

void ISR_Susp(void) interrupt 0
{
	Sleep = TRUE;
	EZUSB_IRQ_CLEAR();
	USBIRQ = bmSUSP;
}

void ISR_Highspeed(void) interrupt 0
{
	if (EZUSB_HIGHSPEED()) {
		pConfigDscr = pHighSpeedConfigDscr;
		((CONFIGDSCR xdata *)pConfigDscr)->type = CONFIG_DSCR;
		pOtherConfigDscr = pFullSpeedConfigDscr;
		((CONFIGDSCR xdata *)pOtherConfigDscr)->type = OTHERSPEED_DSCR;

		// This register sets the number of Isoc packets to send per
		// uFrame.  This register is only valid in high speed.
		EP2ISOINPKTS = 0x03;
	}
	else {
		pConfigDscr = pFullSpeedConfigDscr;
		pOtherConfigDscr = pHighSpeedConfigDscr;
	}

	EZUSB_IRQ_CLEAR();
	USBIRQ = bmHSGRANT;
}
void ISR_Ep0ack(void) interrupt 0
{
}
void ISR_Stub(void) interrupt 0
{
}
void ISR_Ep0in(void) interrupt 0
{
}
void ISR_Ep0out(void) interrupt 0
{
	GotEP0Data = TRUE;
	EZUSB_IRQ_CLEAR();
	EPIRQ = bmBIT1;
}
void ISR_Ep1in(void) interrupt 0
{
}
void ISR_Ep1out(void) interrupt 0
{
}
void ISR_Ep2inout(void) interrupt 0
{
}
void ISR_Ep4inout(void) interrupt 0
{
}
void ISR_Ep6inout(void) interrupt 0
{
}
void ISR_Ep8inout(void) interrupt 0
{
}
void ISR_Ibn(void) interrupt 0
{
}
void ISR_Ep0pingnak(void) interrupt 0
{
}
void ISR_Ep1pingnak(void) interrupt 0
{
}
void ISR_Ep2pingnak(void) interrupt 0
{
}
void ISR_Ep4pingnak(void) interrupt 0
{
}
void ISR_Ep6pingnak(void) interrupt 0
{
}
void ISR_Ep8pingnak(void) interrupt 0
{
}
void ISR_Errorlimit(void) interrupt 0
{
}
void ISR_Ep2piderror(void) interrupt 0
{
}
void ISR_Ep4piderror(void) interrupt 0
{
}
void ISR_Ep6piderror(void) interrupt 0
{
}
void ISR_Ep8piderror(void) interrupt 0
{
}
void ISR_Ep2pflag(void) interrupt 0
{
}
void ISR_Ep4pflag(void) interrupt 0
{
}
void ISR_Ep6pflag(void) interrupt 0
{
}
void ISR_Ep8pflag(void) interrupt 0
{
}
void ISR_Ep2eflag(void) interrupt 0
{
}
void ISR_Ep4eflag(void) interrupt 0
{
}
void ISR_Ep6eflag(void) interrupt 0
{
}
void ISR_Ep8eflag(void) interrupt 0
{
}
void ISR_Ep2fflag(void) interrupt 0
{
}
void ISR_Ep4fflag(void) interrupt 0
{
}
void ISR_Ep6fflag(void) interrupt 0
{
}
void ISR_Ep8fflag(void) interrupt 0
{
}
void ISR_GpifComplete(void) interrupt 0
{
}
void ISR_GpifWaveform(void) interrupt 0
{
}

