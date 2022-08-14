onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Barrel
add wave -noupdate -label shift_type /testbench/U1/shift_type
add wave -noupdate -label data_in -radix hexadecimal /testbench/U1/data_in
add wave -noupdate -label data_out -radix hexadecimal /testbench/U1/data_out
add wave -noupdate -label shift -radix hexadecimal /testbench/U1/shift
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {20000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 85
configure wave -valuecolwidth 64
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {235352 ps}
