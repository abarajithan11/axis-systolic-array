
source  config.tcl

set BOARD        $TARGET
set PROJECT_NAME sa_${BOARD}
set RTL_DIR      ../../rtl

source ../../tcl/fpga/${BOARD}.tcl
source ../../tcl/fpga/vivado.tcl