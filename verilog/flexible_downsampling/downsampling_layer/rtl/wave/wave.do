onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /tb_flexible_downsampling/uut/clk
add wave -noupdate -radix unsigned /tb_flexible_downsampling/uut/ps
add wave -noupdate -radix unsigned /tb_flexible_downsampling/ready
add wave -noupdate -radix unsigned /tb_flexible_downsampling/uut/channel_idx
add wave -noupdate -radix unsigned -childformat {{{/tb_flexible_downsampling/uut/ofmap_slice[0]} -radix unsigned} {{/tb_flexible_downsampling/uut/ofmap_slice[1]} -radix unsigned} {{/tb_flexible_downsampling/uut/ofmap_slice[2]} -radix unsigned} {{/tb_flexible_downsampling/uut/ofmap_slice[3]} -radix unsigned} {{/tb_flexible_downsampling/uut/ofmap_slice[4]} -radix unsigned} {{/tb_flexible_downsampling/uut/ofmap_slice[5]} -radix unsigned} {{/tb_flexible_downsampling/uut/ofmap_slice[6]} -radix unsigned} {{/tb_flexible_downsampling/uut/ofmap_slice[7]} -radix unsigned} {{/tb_flexible_downsampling/uut/ofmap_slice[8]} -radix unsigned} {{/tb_flexible_downsampling/uut/ofmap_slice[9]} -radix unsigned} {{/tb_flexible_downsampling/uut/ofmap_slice[10]} -radix unsigned} {{/tb_flexible_downsampling/uut/ofmap_slice[11]} -radix unsigned} {{/tb_flexible_downsampling/uut/ofmap_slice[12]} -radix unsigned} {{/tb_flexible_downsampling/uut/ofmap_slice[13]} -radix unsigned} {{/tb_flexible_downsampling/uut/ofmap_slice[14]} -radix unsigned} {{/tb_flexible_downsampling/uut/ofmap_slice[15]} -radix unsigned} {{/tb_flexible_downsampling/uut/ofmap_slice[16]} -radix unsigned} {{/tb_flexible_downsampling/uut/ofmap_slice[17]} -radix unsigned} {{/tb_flexible_downsampling/uut/ofmap_slice[18]} -radix unsigned}} -expand -subitemconfig {{/tb_flexible_downsampling/uut/ofmap_slice[0]} {-height 16 -radix unsigned} {/tb_flexible_downsampling/uut/ofmap_slice[1]} {-height 16 -radix unsigned} {/tb_flexible_downsampling/uut/ofmap_slice[2]} {-height 16 -radix unsigned} {/tb_flexible_downsampling/uut/ofmap_slice[3]} {-height 16 -radix unsigned} {/tb_flexible_downsampling/uut/ofmap_slice[4]} {-height 16 -radix unsigned} {/tb_flexible_downsampling/uut/ofmap_slice[5]} {-height 16 -radix unsigned} {/tb_flexible_downsampling/uut/ofmap_slice[6]} {-height 16 -radix unsigned} {/tb_flexible_downsampling/uut/ofmap_slice[7]} {-height 16 -radix unsigned} {/tb_flexible_downsampling/uut/ofmap_slice[8]} {-height 16 -radix unsigned} {/tb_flexible_downsampling/uut/ofmap_slice[9]} {-height 16 -radix unsigned} {/tb_flexible_downsampling/uut/ofmap_slice[10]} {-height 16 -radix unsigned} {/tb_flexible_downsampling/uut/ofmap_slice[11]} {-height 16 -radix unsigned} {/tb_flexible_downsampling/uut/ofmap_slice[12]} {-height 16 -radix unsigned} {/tb_flexible_downsampling/uut/ofmap_slice[13]} {-height 16 -radix unsigned} {/tb_flexible_downsampling/uut/ofmap_slice[14]} {-height 16 -radix unsigned} {/tb_flexible_downsampling/uut/ofmap_slice[15]} {-height 16 -radix unsigned} {/tb_flexible_downsampling/uut/ofmap_slice[16]} {-height 16 -radix unsigned} {/tb_flexible_downsampling/uut/ofmap_slice[17]} {-height 16 -radix unsigned} {/tb_flexible_downsampling/uut/ofmap_slice[18]} {-height 16 -radix unsigned}} /tb_flexible_downsampling/uut/ofmap_slice
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {444 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 296
configure wave -valuecolwidth 100
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
WaveRestoreZoom {0 ns} {764 ns}
