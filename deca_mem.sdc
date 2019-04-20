# round a floating point result (value) to (decimalplaces)
# decimal places
proc tcl::mathfunc::roundto { value decimalplaces } {
    expr {round(10.0 ** $decimalplaces * $value) / 10.0 ** $decimalplaces}
}

#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3

# a little tcl trickery to avoid warnings about too much decimal places
set period [expr roundto(1000000.0 / 50000.0, 3)]
set adc_period [expr roundto(1000000.0 / 10000.0, 3)]

#**************************************************************
# Create Clock
#**************************************************************
create_clock -period $adc_period [get_ports ADC_CLK_10]
create_clock -period $period [get_ports MAX10_CLK1_50]
create_clock -period $period [get_ports MAX10_CLK2_50]

#**************************************************************
# Create Generated Clock
#**************************************************************
derive_pll_clocks



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty



#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************

# we do not care if this multiplication takes a little longer than a single clock cycle ...
set_false_path -from hdmi_tx:i_hdmi_tx|vpg:i_video_pattern_generator|vga_generator:i_vga_generator|lpm_divide:Div1|* \
               -to hdmi_tx:i_hdmi_tx|vpg:i_video_pattern_generator|vga_generator:i_vga_generator|colour_mode.*


#**************************************************************
# Set Multicycle Path
#**************************************************************


#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************



#**************************************************************
# Set Load
#**************************************************************



