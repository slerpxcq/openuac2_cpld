transcript on
if ![file isdirectory verilog_libs] {
	file mkdir verilog_libs
}

vlib verilog_libs/maxii_ver
vmap maxii_ver ./verilog_libs/maxii_ver
vlog -vlog01compat -work maxii_ver {c:/intelfpga_lite/21.1/quartus/eda/sim_lib/maxii_atoms.v}

if {[file exists gate_work]} {
	vdel -lib gate_work -all
}
vlib gate_work
vmap work gate_work

vlog -vlog01compat -work work +incdir+. {fx2lp_uac2_epm1270.vo}

