#ifndef _UAC2_H_
#define _UAC2_H_

// --------------------- Request Types ---------------------
#define RT_STD 0x00
#define RT_CLASS 0x20
#define RT_MASK 0x60

// --------------------- Audio Class Requests ---------------------
#define SC_CUR 0x01
#define SC_RANGE 0x02

// --------------------- AUDIO20 Definitions ---------------------
#define AUDIO_FUNCTION AUDIO
#define FUNCTION_SUBCLASS_UNDEFINED 0x00
#define FUNCTION_PROTOCOL_UNDEFINED 0x00
#define AF_VERSION_02_00 IP_VERSION_02_00
#define AUDIO 0x01
#define INTERFACE_SUBCLASS_UNDEFINED 0x00
#define AUDIOCONTROL 0x01
#define AUDIOSTREAMING 0x02
#define INTERFACE_PROTOCOL_UNDEFINED 0x00
#define IP_VERSION_02_00 0x20
#define FUNCTION_SUBCLASS_UNDEFINED 0x00

#define CS_UNDEFINED 0x20
#define CS_DEVICE 0x21
#define CS_CONFIGURATION 0x22
#define CS_STRING 0x23
#define CS_INTERFACE 0x24
#define CS_ENDPOINT 0x25

#define CS_SAM_FREQ_CONTROL 0x01
#define FU_MUTE_CONTROL 0x01
#define FU_VOLUME_CONTROL 0x02

#define AC_DESCRIPTOR_UNDEFINED 0x00
#define HEADER 0x01
#define INPUT_TERMINAL 0x02
#define OUTPUT_TERMINAL 0x03
#define CLOCK_SOURCE 0x0A
#define FEATURE_UNIT 0x06

#define AS_DESCRIPTOR_UNDEFINED 0x00
#define AS_GENERAL 0x01
#define FORMAT_TYPE 0x02

#define AC_INTERFACE_NUM 0x00
#define AS_INTERFACE_NUM 0x01

#define CLOCK_SOURCE_ID 0x04

#define INPUT_TERMINAL_ID 0x01
#define INPUT_TERMINAL_TYPE 0x0101
#define OUTPUT_TERMINAL_ID 0x03
#define OUTPUT_TERMINAL_TYPE 0x0301
#define FEATURE_UNIT_ID 0x02

#define EP_GENERAL 0x01

// --------------------- User Config ---------------------
#define CS_MIN_FREQ 44100UL
#define CS_MAX_FREQ 1536000UL
#define CS_FREQ_STEP 1UL

#define FU_MIN_VOLUME 0UL
#define FU_MAX_VOLUME 100UL
#define FU_VOLUME_STEP 1UL

#endif