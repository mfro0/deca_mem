set precmd_list { "embed_m68k.tcl" "make_datetime.tcl" }

foreach item $precmd_list {
    post_message "execute $item"
    exec quartus_sh -t $item
}
