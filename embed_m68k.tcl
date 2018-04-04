package require cmdline

post_message "embed_m68k.tcl"

set binfile m68k/simple.bin
set fp [open $binfile r]
fconfigure $fp -translation binary
set bindata [read $fp]
close $fp

set filename simple.vhd
set file [open $filename w]
puts $file "library ieee;"
puts $file "use ieee.std_logic_1164.all;"
puts $file ""
puts $file "    -- VHDL representation of $filename"
puts $file "    -- m68k executable as preloaded RAM contents"
puts $file ""
puts $file "package m68k_binary is"
puts $file "    subtype ubyte is std_logic_vector(7 downto 0);"
puts $file "    type ubyte_array is array (natural range <>) of ubyte;"
puts $file ""
puts $file "    constant m68k_binary    : ubyte_array :="
puts $file "    ("
puts -nonewline $file "        "
set len [string length $bindata]
for {set i 0} {$i < $len} {incr i} {
    set char [string index $bindata $i]
    binary scan $char H2 byte
    puts -nonewline $file "x\""
    puts -nonewline $file $byte
    puts -nonewline $file "\""
    if { ! ([expr $i + 1] == $len) } {
        puts -nonewline $file ", "
    } 
    if { [expr ($i + 1) % 8] == 0 } {
        puts $file ""
        puts -nonewline $file "        "
    }
}
puts $file ""
puts $file "    );"
puts $file "end package m68k_binary;"
close $file
