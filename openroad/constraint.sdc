if {[info exists ::env(PLATFORM)] && $::env(PLATFORM) == "asap7"} {
  set clk_period 10000
} else {
  set clk_period 10
}

set io_delay 0

set clk_ports [get_ports clk]
if {[llength $clk_ports] > 0} {
  set clk_name clk
  create_clock -name $clk_name -period $clk_period $clk_ports

  set non_clock_inputs {}
  foreach input_port [all_inputs] {
    if {[lsearch -exact $clk_ports $input_port] < 0} {
      lappend non_clock_inputs $input_port
    }
  }
} else {
  set clk_name virtual_clock
  create_clock -name $clk_name -period $clk_period
  set non_clock_inputs [all_inputs]
}

if {[llength $non_clock_inputs] > 0} {
  set_input_delay $io_delay -clock $clk_name $non_clock_inputs
}

set output_ports [all_outputs]
if {[llength $output_ports] > 0} {
  set_output_delay $io_delay -clock $clk_name $output_ports
}
