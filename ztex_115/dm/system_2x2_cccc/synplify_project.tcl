#
# TCL Script to build the design using Synopsys Synplify
#

set OPTIMSOC_TCL $env(OPTIMSOC_TCL)
set SYNDIR [file dirname [info script]]

source $OPTIMSOC_TCL/optimsoc_synplify.tcl

project -new

optimsoc_inc_dir $SYNDIR
optimsoc_add_file $SYNDIR/system_2x2_cccc.ucf
optimsoc_add_file $SYNDIR/system_2x2_cccc.sdc
optimsoc_add_file $SYNDIR/system_2x2_cccc.fdc
optimsoc_add_file $SYNDIR/system_2x2_cccc.v

optimsoc_add_file $SYNDIR/../../ipcores/ztex_1_15_mig_39.edf
optimsoc_add_file $SYNDIR/system_2x2_cccc_ztex_ddr.ucf

# GLIP communication interface
optimsoc_add_file $SYNDIR/fx2.ucf
optimsoc_add_file $SYNDIR/fx2.sdc
optimsoc_add_file $SYNDIR/glip_cypressfx2_toplevel.v
optimsoc_add_module cdc

optimsoc_add_module system_2x2_cccc_dm
optimsoc_add_module debug_system
optimsoc_add_module clockmanager.ztex115
optimsoc_add_module fifo_dbg_if
optimsoc_add_module xilinx_ddr.ztex
optimsoc_add_module sram.spartan6

################################################################################
# implementation: "ztex_115_dm_system_2x2_cccc_d_bram"
################################################################################

impl -add ztex_115_dm_system_2x2_cccc_d_bram -type fpga

# implementation attributes
set_option -vlog_std sysv
set_option -project_relative_includes 1
set_option -include_path [optimsoc_get_incdirs]

# pr_1 attributes
set_option -job pr_1 -add par
set_option -job pr_1 -option enable_run 1
set_option -job pr_1 -option run_backannotation 0

# device options
set_option -technology Spartan6
set_option -part XC6SLX150
set_option -package CSG484
set_option -speed_grade -3
set_option -part_companion ""

# compilation/mapping options
set_option -use_fsm_explorer 0
set_option -top_module "system_2x2_cccc"

# mapper_options
set_option -frequency auto
set_option -write_verilog 0
set_option -write_vhdl 0

# xilinx_options
set_option -enhanced_optimization 0

# Xilinx Spartan3
set_option -run_prop_extract 1
set_option -maxfan 10000

set_option -disable_io_insertion 0

set_option -pipe 1
set_option -retiming 0
set_option -update_models_cp 0
set_option -fixgatedclocks 3
set_option -fixgeneratedclocks 3
set_option -no_sequential_opt 1
set_option -resolve_multiple_driver 1

# Xilinx Spartan6
set_option -enable_prepacking 1

# NFilter
set_option -popfeed 0
set_option -constprop 0
set_option -createhierarchy 0

# Xilinx
set_option -fc_phys_opt 0

# sequential_optimization_options
set_option -symbolic_fsm_compiler 1

# Compiler Options
set_option -compiler_compatible 0
set_option -resource_sharing 1
set_option -multi_file_compilation_unit 1
set_option -ucf "$SYNDIR/fx2.ucf $SYNDIR/system_2x2_cccc.ucf"

#automatic place and route (vendor) options
set_option -write_apr_constraint 1

#set result format/file last
project -result_file "$OPTIMSOC_SYN_OUTDIR/ztex_115_dm_system_2x2_cccc_d_bram/ztex_115_dm_system_2x2_cccc_d_bram.edf"

################################################################################
# implementation: "ztex_115_dm_system_2x2_cccc_b_ddr"
################################################################################

impl -add ztex_115_dm_system_2x2_cccc_b_ddr -type fpga

# implementation attributes
set_option -vlog_std sysv
set_option -project_relative_includes 1
set_option -include_path [optimsoc_get_incdirs]

set_option -hdl_define -set "OPTIMSOC_CTRAM_WIRES"

# pr_1 attributes
set_option -job pr_1 -add par
set_option -job pr_1 -option enable_run 1
set_option -job pr_1 -option run_backannotation 0

# device options
set_option -technology Spartan6
set_option -part XC6SLX75
set_option -package CSG484
set_option -speed_grade -3
set_option -part_companion ""

# compilation/mapping options
set_option -use_fsm_explorer 0
set_option -top_module "system_2x2_cccc"

# mapper_options
set_option -frequency auto
set_option -write_verilog 0
set_option -write_vhdl 0

# xilinx_options
set_option -enhanced_optimization 0

# Xilinx Spartan3
set_option -run_prop_extract 1
set_option -maxfan 10000

set_option -disable_io_insertion 0

set_option -pipe 1
set_option -retiming 0
set_option -update_models_cp 0
set_option -fixgatedclocks 3
set_option -fixgeneratedclocks 3
set_option -no_sequential_opt 1
set_option -resolve_multiple_driver 1

# Xilinx Spartan6
set_option -enable_prepacking 1

# NFilter
set_option -popfeed 0
set_option -constprop 0
set_option -createhierarchy 0

# Xilinx
set_option -fc_phys_opt 0

# sequential_optimization_options
set_option -symbolic_fsm_compiler 1

# Compiler Options
set_option -compiler_compatible 0
set_option -resource_sharing 1
set_option -multi_file_compilation_unit 1
set_option -ucf "$SYNDIR/fx2.ucf $SYNDIR/system_2x2_cccc.ucf $SYNDIR/system_2x2_cccc_ddr.ucf"

#automatic place and route (vendor) options
set_option -write_apr_constraint 1

#set result format/file last
project -result_file "$OPTIMSOC_SYN_OUTDIR/ztex_115_dm_system_2x2_cccc_b_ddr/ztex_115_dm_system_2x2_cccc_b_ddr.edf"


################################################################################
# implementation: "ztex_115_dm_system_2x2_cccc_d_ddr"
################################################################################

impl -add ztex_115_dm_system_2x2_cccc_d_ddr -type fpga

# implementation attributes
set_option -vlog_std sysv
set_option -project_relative_includes 1
set_option -include_path [optimsoc_get_incdirs]

set_option -hdl_define -set "OPTIMSOC_CTRAM_WIRES"

# pr_1 attributes
set_option -job pr_1 -add par
set_option -job pr_1 -option enable_run 1
set_option -job pr_1 -option run_backannotation 0

# device options
set_option -technology Spartan6
set_option -part XC6SLX150
set_option -package CSG484
set_option -speed_grade -3
set_option -part_companion ""

# compilation/mapping options
set_option -use_fsm_explorer 0
set_option -top_module "system_2x2_cccc"

# mapper_options
set_option -frequency auto
set_option -write_verilog 0
set_option -write_vhdl 0

# xilinx_options
set_option -enhanced_optimization 0

# Xilinx Spartan3
set_option -run_prop_extract 1
set_option -maxfan 10000

set_option -disable_io_insertion 0

set_option -pipe 1
set_option -retiming 0
set_option -update_models_cp 0
set_option -fixgatedclocks 3
set_option -fixgeneratedclocks 3
set_option -no_sequential_opt 1
set_option -resolve_multiple_driver 1

# Xilinx Spartan6
set_option -enable_prepacking 1

# NFilter
set_option -popfeed 0
set_option -constprop 0
set_option -createhierarchy 0

# Xilinx
set_option -fc_phys_opt 0

# sequential_optimization_options
set_option -symbolic_fsm_compiler 1

# Compiler Options
set_option -compiler_compatible 0
set_option -resource_sharing 1
set_option -multi_file_compilation_unit 1
set_option -ucf "$SYNDIR/fx2.ucf $SYNDIR/system_2x2_cccc.ucf $SYNDIR/system_2x2_cccc_ddr.ucf"

#automatic place and route (vendor) options
set_option -write_apr_constraint 1

#set result format/file last
project -result_file "$OPTIMSOC_SYN_OUTDIR/ztex_115_dm_system_2x2_cccc_d_ddr/system_2x2_cccc_ztex115d_ddr.edf"

project -save synplify.prj
