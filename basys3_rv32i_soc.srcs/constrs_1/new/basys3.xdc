## Basys 3 constraints for the RV32I SoC and triangle rasterizer

## -----------------------------------------------------------------
## 100 MHz system clock
## -----------------------------------------------------------------

set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports clk]

## -----------------------------------------------------------------
## Center push button: active-high reset
## -----------------------------------------------------------------

set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports reset]

## -----------------------------------------------------------------
## VGA red channel
## -----------------------------------------------------------------

set_property -dict { PACKAGE_PIN G19 IOSTANDARD LVCMOS33 } [get_ports {vgaRed[0]}]
set_property -dict { PACKAGE_PIN H19 IOSTANDARD LVCMOS33 } [get_ports {vgaRed[1]}]
set_property -dict { PACKAGE_PIN J19 IOSTANDARD LVCMOS33 } [get_ports {vgaRed[2]}]
set_property -dict { PACKAGE_PIN N19 IOSTANDARD LVCMOS33 } [get_ports {vgaRed[3]}]

## -----------------------------------------------------------------
## VGA green channel
## -----------------------------------------------------------------

set_property -dict { PACKAGE_PIN J17 IOSTANDARD LVCMOS33 } [get_ports {vgaGreen[0]}]
set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports {vgaGreen[1]}]
set_property -dict { PACKAGE_PIN G18 IOSTANDARD LVCMOS33 } [get_ports {vgaGreen[2]}]
set_property -dict { PACKAGE_PIN D18 IOSTANDARD LVCMOS33 } [get_ports {vgaGreen[3]}]

## -----------------------------------------------------------------
## VGA blue channel
## -----------------------------------------------------------------

set_property -dict { PACKAGE_PIN D17 IOSTANDARD LVCMOS33 } [get_ports {vgaBlue[0]}]
set_property -dict { PACKAGE_PIN G17 IOSTANDARD LVCMOS33 } [get_ports {vgaBlue[1]}]
set_property -dict { PACKAGE_PIN K18 IOSTANDARD LVCMOS33 } [get_ports {vgaBlue[2]}]
set_property -dict { PACKAGE_PIN E18 IOSTANDARD LVCMOS33 } [get_ports {vgaBlue[3]}]

## VGA synchronization signals
set_property -dict { PACKAGE_PIN P19 IOSTANDARD LVCMOS33 } [get_ports Hsync]
set_property -dict { PACKAGE_PIN R19 IOSTANDARD LVCMOS33 } [get_ports Vsync]

## -----------------------------------------------------------------
## Debug/status LEDs
## -----------------------------------------------------------------

## LED0: illegal instruction
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports illegal_instruction]

## LED1: instruction-address misalignment
set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports instruction_address_misaligned]

## LED2: data-address misalignment
set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports data_address_misaligned]

## LED3: CPU halted
set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports halted]

## LED4: rasterizer busy
set_property -dict { PACKAGE_PIN W18 IOSTANDARD LVCMOS33 } [get_ports rasterizer_busy]

## LED5: rasterizer done pulse
set_property -dict { PACKAGE_PIN U15 IOSTANDARD LVCMOS33 } [get_ports rasterizer_done]

## -----------------------------------------------------------------
## Configuration voltage
## -----------------------------------------------------------------

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
