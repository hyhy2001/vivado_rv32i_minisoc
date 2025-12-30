# Run xsim without creating a Vivado project (portable, relative paths).
#
# Usage (from vivado_rv32i_minisoc/):
#   vivado -mode batch -source vivado/run_xsim_noproject.tcl
#

set script_dir [file dirname [info script]]
cd [file join $script_dir ".."]

file mkdir vivado/xsim_build
cd vivado/xsim_build

set rtl_files [list \
  ../../rtl/rv32i_core.v \
  ../../rtl/simple_rom.v \
  ../../rtl/simple_ram.v \
  ../../rtl/minisoc_top.v \
  ../../sim/tb_minisoc.v \
]

puts "== xvlog =="
eval exec xvlog --incr --relax $rtl_files

puts "== xelab =="
exec xelab --incr --debug typical --relax -L unisims_ver -L unimacro_ver -L secureip \
  --snapshot tb_minisoc_behav tb_minisoc -log elaborate.log

puts "== xsim =="
exec xsim tb_minisoc_behav -R -log simulate.log -testplusarg romhex=../../software/rom.hex

puts "== simulate.log (tail) =="
set fp [open "simulate.log" r]
set content [read $fp]
close $fp
set lines [split $content "\n"]
set n [llength $lines]
set start [expr {$n - 30}]
if {$start < 0} { set start 0 }
for {set idx $start} {$idx < $n} {incr idx} {
  puts [lindex $lines $idx]
}

quit
