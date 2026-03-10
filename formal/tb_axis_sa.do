onerror {resume}
quietly WaveActivateNextPane {} 0

# clock / reset
add wave -noupdate sim:/tb_axis_sa/clk
add wave -noupdate sim:/tb_axis_sa/rstn

# slave-side interface
add wave -noupdate sim:/tb_axis_sa/dut/s_valid
add wave -noupdate sim:/tb_axis_sa/dut/s_ready
add wave -noupdate sim:/tb_axis_sa/dut/s_last
add wave -noupdate -radix hex sim:/tb_axis_sa/dut/sx_data
add wave -noupdate -radix hex sim:/tb_axis_sa/dut/sk_data

# left-side input staging
add wave -noupdate sim:/tb_axis_sa/dut/en_mac
add wave -noupdate sim:/tb_axis_sa/dut/en_shift
add wave -noupdate -radix hex sim:/tb_axis_sa/dut/sk_reversed
add wave -noupdate -radix hex sim:/tb_axis_sa/dut/xi_delayed
add wave -noupdate -radix hex sim:/tb_axis_sa/dut/ki_delayed

# control pipeline, flowing toward the master side
add wave -noupdate -radix bin sim:/tb_axis_sa/dut/valid
add wave -noupdate -radix bin sim:/tb_axis_sa/dut/vlast
add wave -noupdate -radix bin sim:/tb_axis_sa/dut/m_first
add wave -noupdate -radix bin sim:/tb_axis_sa/dut/a_valid
add wave -noupdate -radix bin sim:/tb_axis_sa/dut/conflict
add wave -noupdate -radix bin sim:/tb_axis_sa/dut/r_copy
add wave -noupdate -radix bin sim:/tb_axis_sa/dut/r_clear
add wave -noupdate -radix bin sim:/tb_axis_sa/dut/r_valid
add wave -noupdate -radix bin sim:/tb_axis_sa/dut/r_last

# PE array data movement
add wave -noupdate -radix hex sim:/tb_axis_sa/dut/xo
add wave -noupdate -radix hex sim:/tb_axis_sa/dut/ko
add wave -noupdate -radix hex sim:/tb_axis_sa/dut/ro

# master-side interface
add wave -noupdate sim:/tb_axis_sa/dut/m_ready
add wave -noupdate sim:/tb_axis_sa/dut/m_valid
add wave -noupdate sim:/tb_axis_sa/dut/m_last
add wave -noupdate -radix hex sim:/tb_axis_sa/dut/m_data

update
WaveRestoreZoom {0 ns} {200 ns}