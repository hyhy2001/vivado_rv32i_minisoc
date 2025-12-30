# Vivado 2025.2 - create a minimal simulation project and run xsim.
#
# Usage (from inside vivado_rv32i_minisoc/):
#   vivado -mode batch -source vivado/run_xsim.tcl
#
# Optional:
#   vivado -mode batch -source vivado/run_xsim.tcl -tclargs xc7a35tcsg324-1
#

set script_dir [file dirname [info script]]
set repo_dir   [file join $script_dir ".."]

set part "xc7a35tcsg324-1"
if { $argc >= 1 } {
  set part [lindex $argv 0]
}

set proj_dir [file join $script_dir "vivado_proj"]
file mkdir $proj_dir

# Create a fresh project per run to avoid directory-lock conflicts on Windows.
set run_tag [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
set proj_name "minisoc_xsim_${run_tag}"
create_project $proj_name $proj_dir -part $part -force

set rtl_files [list \
  [file join $repo_dir "rtl" "rv32i_core.v"] \
  [file join $repo_dir "rtl" "simple_rom.v"] \
  [file join $repo_dir "rtl" "simple_ram.v"] \
  [file join $repo_dir "rtl" "minisoc_top.v"] \
]

set sim_files [list \
  [file join $repo_dir "sim" "tb_minisoc.v"] \
]

add_files -norecurse $rtl_files
add_files -fileset sim_1 -norecurse $sim_files

set_property top tb_minisoc [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

# Pass Verilog plusarg to xsim runtime so $readmemh finds ROM regardless of working dir.
# In a project run, xsim executes from:
#   vivado/vivado_proj/<proj>.sim/sim_1/behav/xsim
# so ROM relative to that folder is:
#   ../../../../../../software/rom.hex
set_property -name {xsim.simulate.xsim.more_options} -value "-testplusarg romhex=../../../../../../software/rom.hex" -objects [get_filesets sim_1]

launch_simulation
run all
close_project
quit
