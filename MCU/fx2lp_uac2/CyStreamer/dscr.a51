;;-----------------------------------------------------------------------------
;;   File:      dscr.a51
;;   Contents:   This file contains descriptor data tables.  
;;
;;   Copyright (c) 2003 Cypress Semiconductor, Inc. All rights reserved
;;-----------------------------------------------------------------------------

   
DSCR_DEVICE   equ   1   ;; Descriptor type: Device
DSCR_CONFIG   equ   2   ;; Descriptor type: Configuration
DSCR_STRING   equ   3   ;; Descriptor type: String
DSCR_INTRFC   equ   4   ;; Descriptor type: Interface
DSCR_ENDPNT   equ   5   ;; Descriptor type: Endpoint
DSCR_DEVQUAL  equ   6   ;; Descriptor type: Device Qualifier
DSCR_IAD	  equ	11

DSCR_DEVICE_LEN   equ   18
DSCR_CONFIG_LEN   equ    9
DSCR_INTRFC_LEN   equ    9
DSCR_ENDPNT_LEN   equ    7
DSCR_DEVQUAL_LEN  equ   10
DSCR_IAD_LEN	  equ	8

ET_CONTROL   equ   0   ;; Endpoint type: Control
ET_ISO       equ   1   ;; Endpoint type: Isochronous
ET_BULK      equ   2   ;; Endpoint type: Bulk
ET_INT       equ   3   ;; Endpoint type: Interrupt

;;-----------------------------------------------------------------------------
;; Audio20 Definitions
;;-----------------------------------------------------------------------------

AUDIO_FUNCTION 					equ AUDIO
FUNCTION_SUBCLASS_UNDEFINED 	equ 0x00
FUNCTION_PROTOCOL_UNDEFINED 	equ 0x00
AF_VERSION_02_00 				equ IP_VERSION_02_00
AUDIO 							equ 0x01
INTERFACE_SUBCLASS_UNDEFINED 	equ 0x00
AUDIOCONTROL 					equ 0x01
AUDIOSTREAMING 					equ 0x02
INTERFACE_PROTOCOL_UNDEFINED 	equ 0x00
IP_VERSION_02_00 				equ 0x20

CS_UNDEFINED 					equ 0x20
CS_DEVICE 						equ 0x21
CS_CONFIGURATION 				equ 0x22
CS_STRING 						equ 0x23
CS_INTERFACE 					equ 0x24
CS_ENDPOINT 					equ 0x25

CS_SAM_FREQ_CONTROL 			equ 0x01
FU_MUTE_CONTROL 				equ 0x01  
FU_VOLUME_CONTROL 				equ 0x02

AC_DESCRIPTOR_UNDEFINED 		equ 0x00
HEADER 							equ 0x01
INPUT_TERMINAL 					equ 0x02
OUTPUT_TERMINAL 				equ 0x03
CLOCK_SOURCE 					equ 0x0A
FEATURE_UNIT 					equ 0x06

AS_DESCRIPTOR_UNDEFINED 		equ 0x00
AS_GENERAL 						equ 0x01
FORMAT_TYPE 					equ 0x02

AC_INTERFACE_NUM 				equ 0x00
AS_INTERFACE_NUM 				equ 0x01

CLOCK_SOURCE_ID 				equ 0x04

INPUT_TERMINAL_ID 				equ 0x01
INPUT_TERMINAL_TYPE 			equ 0x0101  
OUTPUT_TERMINAL_ID 				equ 0x03
OUTPUT_TERMINAL_TYPE 			equ 0x0103  
FEATURE_UNIT_ID 				equ 0x02
	
EP_GENERAL 						equ 0x01
	
FORMAT_TYPE_I					equ 0x01

;;-----------------------------------------------------------------------------
;; Endpoint Configuration
;;-----------------------------------------------------------------------------

OUT_EP_ADDR 					equ 0x02 ; EP2 OUT
OUT_EP_ATTRIB 					equ 0x05
FB_EP_ADDR 						equ 0x88 ; EP8 IN
FB_EP_ATTRIB 					equ 0x11
OUT_EP_PKTSZ 					equ 0x0014
FB_EP_PKTSZ	 					equ 0x0400
OUT_EP_INTERVAL					equ 0x01
FB_EP_INTERVAL					equ 0x04

public      DeviceDscr, DeviceQualDscr, HighSpeedConfigDscr, FullSpeedConfigDscr, StringDscr, UserDscr

;DSCR   SEGMENT   CODE

;;-----------------------------------------------------------------------------
;; Global Variables
;;-----------------------------------------------------------------------------
;      rseg DSCR     ;; locate the descriptor table in on-part memory.

CSEG   AT 100H

DeviceDscr:   
      db   DSCR_DEVICE_LEN      ;; Descriptor length
      db   DSCR_DEVICE   ;; Decriptor type
      dw   0002H      ;; Specification Version (BCD)
      db   0EFH        ;; Device class
      db   02H         ;; Device sub-class
      db   01H         ;; Device sub-sub-class
      db   64         ;; Maximum packet size
	  ;; STM32 speaker
      ;; dw   08304H      ;; Vendor ID
      ;; dw   03057H      ;; Product ID (Sample Device)
	  ;; XMOS speaker
      ;; dw   0B120H      ;; Vendor ID
      ;; dw   00920H      ;; Product ID (Sample Device)
	  ;; xDuoo
      dw   02A15H      ;; Vendor ID
      dw   00788H      ;; Product ID (Sample Device)
      dw   0000H      ;; Product version ID
      db   1         ;; Manufacturer string index
      db   2         ;; Product string index
      db   0         ;; Serial number string index
      db   1         ;; Number of configurations

org (($ / 2) +1) * 2

DeviceQualDscr:
      db   DSCR_DEVQUAL_LEN   ;; Descriptor length
      db   DSCR_DEVQUAL   ;; Decriptor type
      dw   0002H      ;; Specification Version (BCD)
      db   0EFH        ;; Device class
      db   02H         ;; Device sub-class
      db   01H         ;; Device sub-sub-class
      db   64         ;; Maximum packet size
      db   1         ;; Number of configurations
      db   0         ;; Reserved

org (($ / 2) +1) * 2

HighSpeedConfigDscr:   
      db   DSCR_CONFIG_LEN              ;; Descriptor length
      db   DSCR_CONFIG                  ;; Descriptor type
      db   (HighSpeedConfigDscrEnd-HighSpeedConfigDscr) mod 256 ;; Total Length (LSB)
      db   (HighSpeedConfigDscrEnd-HighSpeedConfigDscr)  /  256 ;; Total Length (MSB)
      db   2      						;; Number of interfaces
      db   1      						;; Configuration number
      db   0      						;; Configuration string
      db   0x80  					 	;; Attributes (b7 - buspwr, b6 - selfpwr, b5 - rwu)
      db   50      						;; Power requirement (div 2 ma)
		  
	;;  --------------------- Interface association descriptor ---------------------
	db DSCR_IAD_LEN						;; bLength
	db DSCR_IAD							;; bDescriptorType
	db AC_INTERFACE_NUM					;; bFirstInterface
	db 2								;; bInterfaceCount
	db AUDIO_FUNCTION					;; bFunctionClass
	db FUNCTION_SUBCLASS_UNDEFINED		;; bFunctionSubClass
	db AF_VERSION_02_00					;; bFunctionProtocol
	db 0								;; iFunction

	;; --------------------- AC interface descriptor ---------------------
	;; Standard
	db DSCR_INTRFC_LEN					;; bLength
	db DSCR_INTRFC						;; bDescriptorType
	db AC_INTERFACE_NUM					;; bInterfaceNumber
	db 0								;; bAlternateSetting
	db 0								;; bNumEndpoints
	db AUDIO 							;; bInterfaceClass
	db AUDIOCONTROL						;; bInterfaceSubClass
	db IP_VERSION_02_00					;; bInterfaceProtocol
	db 0								;; iInterface
AudioControlDscr:
	;; Class specific
	db 9								;; bLength
	db CS_INTERFACE						;; bDescriptorType
	db HEADER							;; bDescriptorSubtype
	dw 0x0002							;; bcdADC
	db FUNCTION_SUBCLASS_UNDEFINED		;; bCategory
	db (AudioControlDscrEnd-AudioControlDscr) mod 256		;; wTotalLength
	db (AudioControlDscrEnd-AudioControlDscr) /   256
	db 0x00								;; bmControls

	;; Clock source
	db 8								;; bLength
	db CS_INTERFACE						;; bDescriptorType
	db CLOCK_SOURCE						;; bDescriptorSubtype
	db CLOCK_SOURCE_ID					;; bClockID
	db 0x03								;; bmAttributes
	db 0x03								;; bmControls: 
	db 0x00								;; bAssocTerminal
	db 0x00								;; iClockSource

	;; Input terminal
	db 17								;; bLength
	db CS_INTERFACE						;; bDescriptorType
	db INPUT_TERMINAL					;; bDescriptorSubtype
	db INPUT_TERMINAL_ID				;; bTerminalID
	dw INPUT_TERMINAL_TYPE				;; wTerminalType
	db 0x00								;; bAssocTerminal
	db CLOCK_SOURCE_ID					;; bCSourceID
	db 0x02								;; bNrChannels
	db 0x03								;; bmChannelConfig
	db 0x00
	db 0x00
	db 0x00
	db 0x00 							;; iChannelNames
	db 0x00 							;; bmControls
	db 0x00
	db 0x00								;; iTerminal

	;; Feature unit
	db 14								;; bLength
	db CS_INTERFACE						;; bDescriptorType
	db FEATURE_UNIT						;; bDescriptorSubtype
	db FEATURE_UNIT_ID					;; bUnitID
	db INPUT_TERMINAL_ID				;; bSourceID
	db 0x0f								;; bmaControls(0)
	db 0x00
	db 0x00
	db 0x00
	db 0x0f								;; bmaControls(1)
	db 0x00
	db 0x00
	db 0x00
	db 0x00								;; iFeature

	;; Output terminal
	db 12								;; bLength
	db CS_INTERFACE						;; bDescriptorType
	db OUTPUT_TERMINAL					;; bDescriptorSubtype
	db OUTPUT_TERMINAL_ID				;; bTerminalID
	dw OUTPUT_TERMINAL_TYPE				;; wTerminalType
	db 0x00								;; bAssocTerminal
	db FEATURE_UNIT_ID					;; bSourceID
	db CLOCK_SOURCE_ID					;; bCSourceID
	db 0x00								;; bmControls
	db 0x00
	db 0x00								;; iTerminal
AudioControlDscrEnd:
	;; --------------------- AS interface descriptor ---------------------
	;; --------------------- Alternate setting 0 (No endpoint) ---------------------
	;; Standard
	db DSCR_INTRFC_LEN					;; bLength
	db DSCR_INTRFC						;; bDescriptorType
	db AS_INTERFACE_NUM					;; bInterfaceNumber
	db 0x00 							;; bAlternateSetting
	db 0x00								;; bNumEndpoints
	db AUDIO							;; bInterfaceClass
	db AUDIOSTREAMING					;; bInterfaceSubClass
	db IP_VERSION_02_00					;; bInterfaceProtocol
	db 0								;; iInterface

	;; --------------------- Alternate setting 1 (1x OUT, 1x IN, PCM 32bit) ---------------------
	;; Standard
	db DSCR_INTRFC_LEN					;; bLength
	db DSCR_INTRFC						;; bDescriptorType
	db AS_INTERFACE_NUM					;; bInterfaceNumber
	db 1 								;; bAlternateSetting
	db 2								;; bNumEndpoints
	db AUDIO							;; bInterfaceClass
	db AUDIOSTREAMING					;; bInterfaceSubClass
	db IP_VERSION_02_00					;; bInterfaceProtocol
	db 0								;; iInterface

	;; Class specific
	db 16								;; bLength
	db CS_INTERFACE						;; bDescriptorType
	db AS_GENERAL						;; bDescriptorSubtype
	db INPUT_TERMINAL_ID				;; bTerminalLink
	db 0x00								;; bmControls
	db FORMAT_TYPE_I					;; bFormatType
	db 0x01								;; bmFormats: PCM; Check Frmts20 section A.2
	db 0x00
	db 0x00
	db 0x00
	db 0x02								;; bNrChannels
	db 0x03								;; bmChannelConfig: FL FR; See Audio20 section 4.1
	db 0x00
	db 0x00
	db 0x00
	db 0x00								;; iChannelNames

	;; Format type I descriptor
	db 6								;; bLength
	db CS_INTERFACE						;; bDescriptorType
	db FORMAT_TYPE						;; bDescriptorSubtype
	db FORMAT_TYPE_I					;; bFormatType
	db 4								;; bSubslotSize
	db 32								;; bBitResolution

	;; AS audio data endpoint descriptor
	;; Standard
	db DSCR_ENDPNT_LEN					;; bLength
	db DSCR_ENDPNT						;; bDescriptorType
	db OUT_EP_ADDR						;; bEndpointAddress
	db OUT_EP_ATTRIB					;; bmAttributes
	dw OUT_EP_PKTSZ						;; wMaxPacketSize
	db OUT_EP_INTERVAL					;; bInterval

	;; Class specific
	db 8								;; bLength
	db CS_ENDPOINT						;; bDescriptorType
	db EP_GENERAL						;; bDescriptorSubtype
	db 0x00								;; bmAttributes
	db 0x00								;; bmControls
	db 0x00								;; bLockDelayUnits
	db 0x00								;; wLockDelay
	db 0x00

	;; AS audio feedback endpoint descriptor
	;; Standard
	db DSCR_ENDPNT_LEN 					;; bLength
	db DSCR_ENDPNT						;; bDescriptorType
	db FB_EP_ADDR						;; bEndpointAddress
	db FB_EP_ATTRIB						;; bmAttributes
	dw FB_EP_PKTSZ						;; wMaxPacketSize
	db FB_EP_INTERVAL					;; bInterval

	;; --------------------- Alternate setting 2 (1x OUT, 1x IN, PCM 24bit) ---------------------
	db DSCR_INTRFC_LEN					;; bLength
	db DSCR_INTRFC						;; bDescriptorType
	db AS_INTERFACE_NUM					;; bInterfaceNumber
	db 2 							    ;; bAlternateSetting
	db 2								;; bNumEndpoints
	db AUDIO							;; bInterfaceClass
	db AUDIOSTREAMING					;; bInterfaceSubClass
	db IP_VERSION_02_00					;; bInterfaceProtocol
	db 0x00								;; iInterface

	;; Class specific
	db 16								;; bLength
	db CS_INTERFACE						;; bDescriptorType
	db AS_GENERAL						;; bDescriptorSubtype
	db INPUT_TERMINAL_ID				;; bTerminalLink
	db 0x00								;; bmControls
	db FORMAT_TYPE_I					;; bFormatType
	db 0x01								;; bmFormats: PCM; Check Frmts20 section A.2
	db 0x00
	db 0x00
	db 0x00
	db 0x02								;; bNrChannels
	db 0x03								;; bmChannelConfig
	db 0x00
	db 0x00
	db 0x00
	db 0x00								;; iChannelNames

	;; Format type I descriptor
	db 6								;; bLength
	db CS_INTERFACE						;; bDescriptorType
	db FORMAT_TYPE						;; bDescriptorSubtype
	db FORMAT_TYPE_I					;; bFormatType
	db 4								;; bSubslotSize
	db 24								;; bBitResolution

	;; AS audio data endpoint descriptor
	;; Standard
	db DSCR_ENDPNT_LEN					;; bLength
	db DSCR_ENDPNT						;; bDescriptorType
	db OUT_EP_ADDR						;; bEndpointAddress
	db OUT_EP_ATTRIB					;; bmAttributes
	dw OUT_EP_PKTSZ						;; wMaxPacketSize
	db OUT_EP_INTERVAL					;; bInterval

	;; Class specific
	db 8								;; bLength
	db CS_ENDPOINT						;; bDescriptorType
	db EP_GENERAL						;; bDescriptorSubtype
	db 0x00								;; bmAttributes
	db 0x00								;; bmControls
	db 0x00								;; bLockDelayUnits
	db 0x00								;; wLockDelay
	db 0x00

	;; AS audio feedback endpoint descriptor
	;; Standard
	db DSCR_ENDPNT_LEN 					;; bLength
	db DSCR_ENDPNT						;; bDescriptorType
	db FB_EP_ADDR						;; bEndpointAddress
	db FB_EP_ATTRIB						;; bmAttributes
	dw FB_EP_PKTSZ						;; wMaxPacketSize 
	db FB_EP_INTERVAL					;; bInterval

	;;--------------------- Alternate setting 3 (1x OUT, 1x IN, PCM 16bit) ---------------------
	db DSCR_INTRFC_LEN					;; bLength
	db DSCR_INTRFC						;; bDescriptorType
	db AS_INTERFACE_NUM					;; bInterfaceNumber
	db 3 							    ;; bAlternateSetting
	db 2								;; bNumEndpoints
	db AUDIO							;; bInterfaceClass
	db AUDIOSTREAMING					;; bInterfaceSubClass
	db IP_VERSION_02_00					;; bInterfaceProtocol
	db 0x00								;; iInterface

	;; Class specific
	db 16								;; bLength
	db CS_INTERFACE						;; bDescriptorType
	db AS_GENERAL						;; bDescriptorSubtype
	db INPUT_TERMINAL_ID				;; bTerminalLink
	db 0x00								;; bmControls
	db FORMAT_TYPE_I					;; bFormatType
	db 0x01								;; bmFormats: PCM; Check Frmts20 section A.2
	db 0x00
	db 0x00
	db 0x00
	db 0x02								;; bNrChannels
	db 0x03								;; bmChannelConfig
	db 0x00
	db 0x00
	db 0x00
	db 0x00								;; iChannelNames

	;; Format type I descriptor
	db 6								;; bLength
	db CS_INTERFACE						;; bDescriptorType
	db FORMAT_TYPE						;; bDescriptorSubtype
	db FORMAT_TYPE_I					;; bFormatType
	db 2								;; bSubslotSize
	db 16								;; bBitResolution

	;; AS audio data endpoint descriptor
	;; Standard
	db DSCR_ENDPNT_LEN					;; bLength
	db DSCR_ENDPNT						;; bDescriptorType
	db OUT_EP_ADDR						;; bEndpointAddress
	db OUT_EP_ATTRIB					;; bmAttributes
	dw OUT_EP_PKTSZ						;; wMaxPacketSize
	db OUT_EP_INTERVAL					;; bInterval

	;; Class specific
	db 8								;; bLength
	db CS_ENDPOINT						;; bDescriptorType
	db EP_GENERAL						;; bDescriptorSubtype
	db 0x00								;; bmAttributes
	db 0x00								;; bmControls
	db 0x00								;; bLockDelayUnits
	db 0x00								;; wLockDelay
	db 0x00

	;; AS audio feedback endpoint descriptor
	;; Standard
	db DSCR_ENDPNT_LEN 					;; bLength
	db DSCR_ENDPNT						;; bDescriptorType
	db FB_EP_ADDR						;; bEndpointAddress
	db FB_EP_ATTRIB						;; bmAttributes
	dw FB_EP_PKTSZ						;; wMaxPacketSize 
	db FB_EP_INTERVAL					;; bInterval

	;;--------------------- Alternate setting 4 (1x OUT, 1x IN, DSD native) ---------------------
	db DSCR_INTRFC_LEN					;; bLength
	db DSCR_INTRFC						;; bDescriptorType
	db AS_INTERFACE_NUM					;; bInterfaceNumber
	db 4 							    ;; bAlternateSetting
	db 2								;; bNumEndpoints
	db AUDIO							;; bInterfaceClass
	db AUDIOSTREAMING					;; bInterfaceSubClass
	db IP_VERSION_02_00					;; bInterfaceProtocol
	db 0x00								;; iInterface

	;; Class specific
	db 16								;; bLength
	db CS_INTERFACE						;; bDescriptorType
	db AS_GENERAL						;; bDescriptorSubtype
	db INPUT_TERMINAL_ID				;; bTerminalLink
	db 0x00								;; bmControls
	db FORMAT_TYPE_I					;; bFormatType
	db 0x00								;; bmFormats: Type I raw data; Check Frmts20 section A.2
	db 0x00
	db 0x00
	db 0x80
	db 0x02								;; bNrChannels
	db 0x03								;; bmChannelConfig
	db 0x00
	db 0x00
	db 0x00
	db 0x00								;; iChannelNames

	;; Format type I descriptor
	db 6								;; bLength
	db CS_INTERFACE						;; bDescriptorType
	db FORMAT_TYPE						;; bDescriptorSubtype
	db FORMAT_TYPE_I					;; bFormatType
	db 4								;; bSubslotSize
	db 32								;; bBitResolution

	;; AS audio data endpoint descriptor
	;; Standard
	db DSCR_ENDPNT_LEN					;; bLength
	db DSCR_ENDPNT						;; bDescriptorType
	db OUT_EP_ADDR						;; bEndpointAddress
	db OUT_EP_ATTRIB					;; bmAttributes
	dw OUT_EP_PKTSZ						;; wMaxPacketSize
	db OUT_EP_INTERVAL					;; bInterval

	;; Class specific
	db 8								;; bLength
	db CS_ENDPOINT						;; bDescriptorType
	db EP_GENERAL						;; bDescriptorSubtype
	db 0x00								;; bmAttributes
	db 0x00								;; bmControls
	db 0x00								;; bLockDelayUnits
	db 0x00								;; wLockDelay
	db 0x00

	;; AS audio feedback endpoint descriptor
	;; Standard
	db DSCR_ENDPNT_LEN 					;; bLength
	db DSCR_ENDPNT						;; bDescriptorType
	db FB_EP_ADDR						;; bEndpointAddress
	db FB_EP_ATTRIB						;; bmAttributes
	dw FB_EP_PKTSZ						;; wMaxPacketSize 
	db FB_EP_INTERVAL					;; bInterval
		
HighSpeedConfigDscrEnd:   

org (($ / 2) +1) * 2

FullSpeedConfigDscr:   
FullSpeedConfigDscrEnd:   

org (($ / 2) +1) * 2

StringDscr:

StringDscr0:   
      db   StringDscr0End-StringDscr0      ;; String descriptor length
      db   DSCR_STRING
      db   09H,04H
StringDscr0End:

StringDscr1:   
      db   StringDscr1End-StringDscr1      ;; String descriptor length
      db   DSCR_STRING
      db   'C',00
      db   'y',00
      db   'p',00
      db   'r',00
      db   'e',00
      db   's',00
      db   's',00
StringDscr1End:

StringDscr2:   
      db   StringDscr2End-StringDscr2      ;; Descriptor length
      db   DSCR_STRING
      db   'C',00
      db   'Y',00
      db   '-',00
      db   'S',00
      db   't',00
      db   'r',00
      db   'e',00
      db   'a',00
      db   'm',00
StringDscr2End:

/*StringDscr3:   
      db   StringDscr3End-StringDscr3      ;; Descriptor length
      db   DSCR_STRING
      db   'B',00
      db   'u',00
      db   'l',00
      db   'k',00
      db   '-',00
      db   'I',00
      db   'N',00
StringDscr3End:
*/
UserDscr:      
      dw   0000H
      end
      
