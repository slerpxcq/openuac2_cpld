# 2024/12/21
Fix sram_we_n glitch

# 2024/12/22
Testing circular buffer

# 2024/12/23
48k/32bit working

# 2024/12/25
Send feedback value to host

# 2024/12/26
Solved LSByte of feedback value is always wrong: soldering problem

# 2024/12/27
Solved feedback value missing at higher frequency

# 2024/12/28
I2C interface

# 2024/12/29
Register file, Audio requests

# 2024/12/30
Made 44k1 work
Fixed feedback loop oscillation at low sampling frequency 

# 2025/1/2
Fixed Feedback does not converge except for 352.8k; Maybe due to delay of 1 frame?
Make 16bit work

# 2025/1/3
DoP detector

# 2024/1/9
frequency doubler

# 2024/1/19
Solved missing rd_en pulse in circ_buf: changed rd_req generation method in i2s_master

# 2024/1/24
Added DoP master

# 2024/1/25
audio_if
Zero packet detection, for DoP playback

# TODO:
CPLD DoP detction report to MCU, send command to CODEC to change format

# NOTE
Handshake is not needed is the difference of speed is large (3x+)