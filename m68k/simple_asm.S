
*
* simple m68k startup routine
* 
* code is supposed to start at address 0
*

                .org    0

_start:         .long   initialstack
                .long   initialpc

initialpc:
loop:           lea     hello_world,%sp
                bsr     _puts
                bra.s   loop


                .data
                .even
hello_world:
                .ascii  "Hello World"
                .byte   13,10,0

                .bss
                .even
stack:          .ds.l   0x10
initialstack:

