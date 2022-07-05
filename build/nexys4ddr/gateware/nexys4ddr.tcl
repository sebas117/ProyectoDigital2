
# Create Project

create_project -force -name nexys4ddr -part xc7a100t-CSG324-1
set_msg_config -id {Common 17-55} -new_severity {Warning}

# Add Sources

read_verilog {/home/sebastian/ElectronicaDigital2/LabDigital2022_1/SocProject/SoC_myProject_2022/SoC_myProject_2022/module/verilog/camara/camara.v}
read_verilog {/home/sebastian/ElectronicaDigital2/LabDigital2022_1/SocProject/SoC_myProject_2022/SoC_myProject_2022/module/verilog/camara/buffer_ram_dp.v}
read_verilog {/home/sebastian/ElectronicaDigital2/LabDigital2022_1/SocProject/SoC_myProject_2022/SoC_myProject_2022/module/verilog/camara/cam_read.v}
read_verilog {/home/sebastian/ElectronicaDigital2/LabDigital2022_1/SocProject/SoC_myProject_2022/SoC_myProject_2022/module/verilog/camara/procesamiento.v}
read_verilog {/home/sebastian/ElectronicaDigital2/LabDigital2022_1/SocProject/SoC_myProject_2022/SoC_myProject_2022/module/verilog/camara/VGA_driver.v}
read_verilog {/home/sebastian/ElectronicaDigital2/LabDigital2022_1/SocProject/SoC_myProject_2022/SoC_myProject_2022/module/verilog/camara/PLL/clk24_25_nexys4.v}
read_verilog {/home/sebastian/ElectronicaDigital2/LabDigital2022_1/SocProject/SoC_myProject_2022/SoC_myProject_2022/module/verilog/pwm/pwm.v}
read_verilog {/home/sebastian/ElectronicaDigital2/LabDigital2022_1/SocProject/SoC_myProject_2022/SoC_myProject_2022/module/verilog/infrarrojo/infrarrojo.v}
read_verilog {/opt/Litex/pythondata-cpu-picorv32/pythondata_cpu_picorv32/verilog/picorv32.v}
read_verilog {/home/sebastian/ElectronicaDigital2/LabDigital2022_1/SocProject/SoC_myProject_2022/SoC_myProject_2022/build/nexys4ddr/gateware/nexys4ddr.v}

# Add EDIFs


# Add IPs


# Add constraints

read_xdc nexys4ddr.xdc
set_property PROCESSING_ORDER EARLY [get_files nexys4ddr.xdc]

# Add pre-synthesis commands


# Synthesis

synth_design -directive default -top nexys4ddr -part xc7a100t-CSG324-1

# Synthesis report

report_timing_summary -file nexys4ddr_timing_synth.rpt
report_utilization -hierarchical -file nexys4ddr_utilization_hierarchical_synth.rpt
report_utilization -file nexys4ddr_utilization_synth.rpt

# Optimize design

opt_design -directive default

# Add pre-placement commands


# Placement

place_design -directive default

# Placement report

report_utilization -hierarchical -file nexys4ddr_utilization_hierarchical_place.rpt
report_utilization -file nexys4ddr_utilization_place.rpt
report_io -file nexys4ddr_io.rpt
report_control_sets -verbose -file nexys4ddr_control_sets.rpt
report_clock_utilization -file nexys4ddr_clock_utilization.rpt

# Add pre-routing commands


# Routing

route_design -directive default
phys_opt_design -directive default
write_checkpoint -force nexys4ddr_route.dcp

# Routing report

report_timing_summary -no_header -no_detailed_paths
report_route_status -file nexys4ddr_route_status.rpt
report_drc -file nexys4ddr_drc.rpt
report_timing_summary -datasheet -max_paths 10 -file nexys4ddr_timing.rpt
report_power -file nexys4ddr_power.rpt
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]

# Bitstream generation

write_bitstream -force nexys4ddr.bit 
write_cfgmem -force -format bin -interface spix4 -size 16 -loadbit "up 0x0 nexys4ddr.bit" -file nexys4ddr.bin

# End

quit