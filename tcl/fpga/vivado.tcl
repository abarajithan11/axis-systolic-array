# Top level rtl module
add_files [glob $RTL_DIR/**] config.svh
update_compile_order -fileset sources_1

set_property top top [current_fileset]
create_bd_cell -type module -reference top top_0

# Connect AXI Lite
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config " Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master $PS_M_AXI_0 Slave {/top_0/s_axi} ddr_seg {Auto} intc_ip {New AXI SmartConnect} master_apm {0}"  [get_bd_intf_pins top_0/s_axi]

# Connect full AXI ports. Try connecting directly first, if that fails use automation
if {[catch {
  connect_bd_intf_net [get_bd_intf_pins top_0/m_axi_mm2s_0] [get_bd_intf_pins $PS_S_AXI_0]
  apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config "Clk {$PS_CLK (250 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}"  [get_bd_pins $CLK_0]
} errmsg]} {
  puts "INFO: Direct connection for m_axi_mm2s_0 failed, using automation: $errmsg"
  apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config " Clk_master {$PS_CLK (150 MHz)} Clk_slave {Auto} Clk_xbar {Auto} Master {/top_0/m_axi_mm2s_0} Slave $PS_S_AXI_0 ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}"  [get_bd_intf_pins $PS_S_AXI_0]
}
if {[catch {
  connect_bd_intf_net [get_bd_intf_pins top_0/m_axi_mm2s_1] [get_bd_intf_pins $PS_S_AXI_1]
  apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config "Clk {$PS_CLK (250 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}"  [get_bd_pins $CLK_1]
} errmsg]} {
  puts "INFO: Direct connection for m_axi_mm2s_1 failed, using automation: $errmsg"
  apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config " Clk_master {$PS_CLK (150 MHz)} Clk_slave {Auto} Clk_xbar {Auto} Master {/top_0/m_axi_mm2s_1} Slave $PS_S_AXI_1 ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}"  [get_bd_intf_pins $PS_S_AXI_1]
}
if {[catch {
  connect_bd_intf_net [get_bd_intf_pins top_0/m_axi_mm2s_2] [get_bd_intf_pins $PS_S_AXI_2]
  apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config "Clk {$PS_CLK (250 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}"  [get_bd_pins $CLK_2]
} errmsg]} {
  puts "INFO: Direct connection for m_axi_mm2s_2 failed, using automation: $errmsg"
  apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config " Clk_master {$PS_CLK (150 MHz)} Clk_slave {Auto} Clk_xbar {Auto} Master {/top_0/m_axi_mm2s_2} Slave $PS_S_AXI_2 ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}"  [get_bd_intf_pins $PS_S_AXI_2]
}
if {[catch {
  connect_bd_intf_net [get_bd_intf_pins top_0/m_axi_s2mm] [get_bd_intf_pins $PS_S_AXI_3]
  apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config "Clk {$PS_CLK (250 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}"  [get_bd_pins $CLK_3]
} errmsg]} {
  puts "INFO: Direct connection for m_axi_s2mm failed, using automation: $errmsg"
  apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config " Clk_master {$PS_CLK (150 MHz)} Clk_slave {Auto} Clk_xbar {Auto} Master {/top_0/m_axi_s2mm} Slave $PS_S_AXI_3 ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}"  [get_bd_intf_pins $PS_S_AXI_3]
}



generate_target all [get_files ./${PROJECT_NAME}/${PROJECT_NAME}.srcs/sources_1/bd/design_1/design_1.bd]
make_wrapper -files [get_files ./${PROJECT_NAME}/${PROJECT_NAME}.srcs/sources_1/bd/design_1/design_1.bd] -top
add_files -norecurse ./${PROJECT_NAME}/${PROJECT_NAME}.srcs/sources_1/bd/design_1/hdl/design_1_wrapper.v
set_property top design_1_wrapper [current_fileset]
update_compile_order -fileset sources_1

# Set Config Base Address
set_property range 1G [get_bd_addr_segs $ZYNQ_PS/Data/SEG_top_0_reg0]
set_property offset ${CONFIG_BASEADDR} [get_bd_addr_segs $ZYNQ_PS/Data/SEG_top_0_reg0]
assign_bd_address
save_bd_design

validate_bd_design
save_bd_design

# Implementation
reset_run impl_1
reset_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 24
wait_on_run -timeout 360 impl_1
write_hw_platform -fixed -include_bit -force -file $PROJECT_NAME/design_1_wrapper.xsa

# Reports
open_run impl_1
if {![file exists $PROJECT_NAME/reports]} {exec mkdir $PROJECT_NAME/reports}
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 100 -input_pins -routable_nets -name timing_1 -file $PROJECT_NAME/reports/${PROJECT_NAME}_${BOARD}_${FREQ_MHZ}_timing_report.txt
report_utilization -file $PROJECT_NAME/reports/${PROJECT_NAME}_${BOARD}_${FREQ_MHZ}_utilization_report.txt -name utilization_1
report_power -file $PROJECT_NAME/reports/${PROJECT_NAME}_${BOARD}_${FREQ_MHZ}_power_1.txt -name {power_1}
report_drc -name drc_1 -file $PROJECT_NAME/reports/${PROJECT_NAME}_${BOARD}_${FREQ_MHZ}_drc_1.txt -ruledecks {default opt_checks placer_checks router_checks bitstream_checks incr_eco_checks eco_checks abs_checks}

exec mkdir -p $PROJECT_NAME/output
exec cp "$PROJECT_NAME/$PROJECT_NAME.gen/sources_1/bd/design_1/hw_handoff/design_1.hwh" $PROJECT_NAME/output/
exec cp "$PROJECT_NAME/$PROJECT_NAME.runs/impl_1/design_1_wrapper.bit" $PROJECT_NAME/output/design_1.bit