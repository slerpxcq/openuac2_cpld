# OpenUAC2_CPLD
Yet another implementation of USB Audio Class 2.0 based on CY7C68013A and EPM1270 CPLD

## Features
- Full USB 2.0 HS support
- Asynchronous feedback
- Dedicated external SRAM for buffering
- I2C interface intergrated in CPLD allowing flexible control
- Supported formats:
     - 2 Channels PCM 16/24/32 bit, 44.1kHz to 1536kHz
     - DoP 64 to 512
     - DSD native 64 to 1024

## Environment
- Keil C51
- Quartus Lite 21.1