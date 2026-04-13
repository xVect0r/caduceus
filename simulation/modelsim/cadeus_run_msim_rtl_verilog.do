transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+D:/DeskTop/caduceus/rtl/physical {D:/DeskTop/caduceus/rtl/physical/phy_top.v}
vlog -vlog01compat -work work +incdir+D:/DeskTop/caduceus/rtl/physical {D:/DeskTop/caduceus/rtl/physical/cd_tx.v}
vlog -vlog01compat -work work +incdir+D:/DeskTop/caduceus/rtl/physical {D:/DeskTop/caduceus/rtl/physical/cd_timer.v}
vlog -vlog01compat -work work +incdir+D:/DeskTop/caduceus/rtl/physical {D:/DeskTop/caduceus/rtl/physical/cd_parity.v}
vlog -vlog01compat -work work +incdir+D:/DeskTop/caduceus/rtl/physical {D:/DeskTop/caduceus/rtl/physical/cd_ds.v}
vlog -vlog01compat -work work +incdir+D:/DeskTop/caduceus/rtl/physical {D:/DeskTop/caduceus/rtl/physical/cd_cdc_sync.v}

vlog -vlog01compat -work work +incdir+D:/DeskTop/caduceus/tb {D:/DeskTop/caduceus/tb/tb_phy_top.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L fiftyfivenm_ver -L rtl_work -L work -voptargs="+acc"  tb_phy_top

add wave *
view structure
view signals
run -all
