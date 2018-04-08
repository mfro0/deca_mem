#
# execute each of a list of tcl scripts
#
# meant to be used with the PRE_FLOW_SCRIPT_FILE quartus assignment
# that allows to evaluate a tcl script before analysis starts

set precmd_list { "embed_m68k.tcl" "make_datetime.tcl" }

foreach item $precmd_list {
    post_message "execute $item"
    exec quartus_sh -t $item
}
