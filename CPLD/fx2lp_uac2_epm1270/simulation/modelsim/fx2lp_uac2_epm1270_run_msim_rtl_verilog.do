transcript on
if ![file isdirectory verilog_libs] {
	file mkdir verilog_libs
}

vlib verilog_libs/altera_ver
vmap altera_ver ./verilog_libs/altera_ver
vlog -vlog01compat -work altera_ver {c:/intelfpga_lite/21.1/quartus/eda/sim_lib/altera_primitives.v}

vlib verilog_libs/lpm_ver
vmap lpm_ver ./verilog_libs/lpm_ver
vlog -vlog01compat -work lpm_ver {c:/intelfpga_lite/21.1/quartus/eda/sim_lib/220model.v}

vlib verilog_libs/sgate_ver
vmap sgate_ver ./verilog_libs/sgate_ver
vlog -vlog01compat -work sgate_ver {c:/intelfpga_lite/21.1/quartus/eda/sim_lib/sgate.v}

vlib verilog_libs/altera_mf_ver
vmap altera_mf_ver ./verilog_libs/altera_mf_ver
vlog -vlog01compat -work altera_mf_ver {c:/intelfpga_lite/21.1/quartus/eda/sim_lib/altera_mf.v}

vlib verilog_libs/altera_lnsim_ver
vmap altera_lnsim_ver ./verilog_libs/altera_lnsim_ver
vlog -sv -work altera_lnsim_ver {c:/intelfpga_lite/21.1/quartus/eda/sim_lib/altera_lnsim.sv}

vlib verilog_libs/maxii_ver
vmap maxii_ver ./verilog_libs/maxii_ver
vlog -vlog01compat -work maxii_ver {c:/intelfpga_lite/21.1/quartus/eda/sim_lib/maxii_atoms.v}

if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+D:/Documents/FPGA/fx2lp_uac2_epm1270 {D:/Documents/FPGA/fx2lp_uac2_epm1270/dop_detector.v}
vlog -vlog01compat -work work +incdir+D:/Documents/FPGA/fx2lp_uac2_epm1270 {D:/Documents/FPGA/fx2lp_uac2_epm1270/dsd_master.v}
vlog -vlog01compat -work work +incdir+D:/Documents/FPGA/fx2lp_uac2_epm1270 {D:/Documents/FPGA/fx2lp_uac2_epm1270/feedback_gen.v}
vlog -vlog01compat -work work +incdir+D:/Documents/FPGA/fx2lp_uac2_epm1270 {D:/Documents/FPGA/fx2lp_uac2_epm1270/reg_file.v}
vlog -vlog01compat -work work +incdir+D:/Documents/FPGA/fx2lp_uac2_epm1270 {D:/Documents/FPGA/fx2lp_uac2_epm1270/i2c_if.v}
vlog -vlog01compat -work work +incdir+D:/Documents/FPGA/fx2lp_uac2_epm1270 {D:/Documents/FPGA/fx2lp_uac2_epm1270/pulse_extender.v}
vlog -vlog01compat -work work +incdir+D:/Documents/FPGA/fx2lp_uac2_epm1270 {D:/Documents/FPGA/fx2lp_uac2_epm1270/circ_buf.v}
vlog -vlog01compat -work work +incdir+D:/Documents/FPGA/fx2lp_uac2_epm1270 {D:/Documents/FPGA/fx2lp_uac2_epm1270/fx2_if.v}
vlog -vlog01compat -work work +incdir+D:/Documents/FPGA/fx2lp_uac2_epm1270 {D:/Documents/FPGA/fx2lp_uac2_epm1270/i2s_master.v}
vlog -vlog01compat -work work +incdir+D:/Documents/FPGA/fx2lp_uac2_epm1270 {D:/Documents/FPGA/fx2lp_uac2_epm1270/clk_divider.v}
vlog -vlog01compat -work work +incdir+D:/Documents/FPGA/fx2lp_uac2_epm1270 {D:/Documents/FPGA/fx2lp_uac2_epm1270/pos_edge_det.v}
vlog -vlog01compat -work work +incdir+D:/Documents/FPGA/fx2lp_uac2_epm1270 {D:/Documents/FPGA/fx2lp_uac2_epm1270/dual_edge_det.v}
vlog -vlog01compat -work work +incdir+D:/Documents/FPGA/fx2lp_uac2_epm1270 {D:/Documents/FPGA/fx2lp_uac2_epm1270/audio_if.v}

vlog -vlog01compat -work work +incdir+D:/Documents/FPGA/fx2lp_uac2_epm1270 {D:/Documents/FPGA/fx2lp_uac2_epm1270/tb_dsd_master.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L maxii_ver -L rtl_work -L work -voptargs="+acc"  tb_dsd_master

add wave *
view structure
view signals
run -all
