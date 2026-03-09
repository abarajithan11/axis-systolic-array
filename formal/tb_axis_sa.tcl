set IP axis_sa

vlib build/qverify/work
vlog -sv -work build/qverify/work \
  rtl/sa/mac.sv \
  rtl/sa/n_delay.sv \
  rtl/sa/tri_buffer.sv \
  rtl/sa/pe.sv \
  rtl/sa/${IP}.sv \
  formal/tb_${IP}.sv

formal compile -d tb_${IP} -work build/qverify/work -sva
formal verify -auto_constraint_off
