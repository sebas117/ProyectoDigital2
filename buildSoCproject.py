#!/usr/bin/env python3

from migen import *
from migen.genlib.io import CRG
from migen.genlib.cdc import MultiReg

import nexys4ddr as tarjeta
#import c4e6e10 as tarjeta

from litex.soc.integration.soc_core import *
from litex.soc.integration.builder import *
from litex.soc.interconnect.csr import *

from litex.soc.integration.soc import *

from litex.soc.cores import gpio
from litex.soc.cores import uart
from litex.soc.cores import bitbang

from module import rgbled			# Son los archivos Python
from module import sevensegment
from module import vgacontroller
from module import camara			#camara.py
from module import pwm				#pwm.py
from module import infrarrojo      #infrarrojo.py





# BaseSoC ------------------------------------------------------------------------------------------

class BaseSoC(SoCCore):
	def __init__(self):
		platform = tarjeta.Platform()

		clk_freq =100e6
		## add source verilog

		#platform.add_source("module/verilog/camara.v")
		
		# camara.v
		platform.add_source("module/verilog/camara/camara.v")
		platform.add_source("module/verilog/camara/buffer_ram_dp.v")
		platform.add_source("module/verilog/camara/cam_read.v")
		platform.add_source("module/verilog/camara/procesamiento.v")
		platform.add_source("module/verilog/camara/VGA_driver.v")
		platform.add_source("module/verilog/camara/PLL/clk24_25_nexys4.v")

		#pwm
		platform.add_source("module/verilog/pwm/pwm.v")

		#Motor 

		#infrarrojo

		platform.add_source("module/verilog/infrarrojo/infrarrojo.v")


		# SoC with CPU
		SoCCore.__init__(self, platform,
 			cpu_type="picorv32",
#			cpu_type="vexriscv",
			clk_freq=100e6,
			integrated_rom_size=0x8000,
			integrated_main_ram_size=16*1024)

		# Clock Reset Generation
		self.submodules.crg = CRG(platform.request("clk"), ~platform.request("cpu_reset"))

		# Leds
		SoCCore.add_csr(self,"leds")
		user_leds = Cat(*[platform.request("led", i) for i in range(10)])
		self.submodules.leds = gpio.GPIOOut(user_leds)
		
		# Switchs
		SoCCore.add_csr(self,"switchs")
		user_switchs = Cat(*[platform.request("sw", i) for i in range(8)])
		self.submodules.switchs = gpio.GPIOIn(user_switchs)
		
		# Buttons
		SoCCore.add_csr(self,"buttons")
		user_buttons = Cat(*[platform.request("btn%c" %c) for c in ['c','r','l']])
		self.submodules.buttons = gpio.GPIOIn(user_buttons)
		
		# 7segments Display
		SoCCore.add_csr(self,"display")
		display_segments = Cat(*[platform.request("display_segment", i) for i in range(8)])
		display_digits = Cat(*[platform.request("display_digit", i) for i in range(8)])
		self.submodules.display = sevensegment.SevenSegment(display_segments,display_digits)

		# RGB leds
		SoCCore.add_csr(self,"ledRGB_1")
		self.submodules.ledRGB_1 = rgbled.RGBLed(platform.request("ledRGB",1))
		
		SoCCore.add_csr(self,"ledRGB_2")
		self.submodules.ledRGB_2 = rgbled.RGBLed(platform.request("ledRGB",2))
		
				
		# VGA
		#SoCCore.add_csr(self,"vga_cntrl")  # No hay registros de lectura y escritura para este modulo (No hay un mapa de memoria)
		vga_red = Cat(*[platform.request("vga_red", i) for i in range(4)])
		vga_green = Cat(*[platform.request("vga_green", i) for i in range(4)])
		vga_blue = Cat(*[platform.request("vga_blue", i) for i in range(4)]) #Cat (Concatenar)
		vsync=platform.request("vsync")
		hsync=platform.request("hsync")
		#self.submodules.vga_cntrl = vgacontroller.VGAcontroller(platform.request("hsync"),platform.request("vsync"), vga_red, vga_green, vga_blue)
		
		
		#camara
		SoCCore.add_csr(self,"camara_cntrl")
		SoCCore.add_interrupt(self,"camara_cntrl")
		cam_data_in = Cat(*[platform.request("cam_data_in", i) for i in range(8)])		
		self.submodules.camara_cntrl = camara.Camara(vsync,hsync,vga_red,vga_green,vga_blue,platform.request("cam_xclk"),platform.request("cam_pwdn"),platform.request("cam_pclk"),cam_data_in,platform.request("cam_vsync"),platform.request("cam_href"))

	

		#pwm
		SoCCore.add_csr(self,"pwm_cntrl")
		self.submodules.pwm_cntrl = pwm.Pwm(platform.request("pwm"))

		#Infrarojo
		SoCCore.add_csr(self,"infra_cntrl")
		self.submodules.infra_cntrl = infrarrojo.Infrarrojo(platform.request("infra"),platform.request("motor"))

		# I2C
		 
        #self.submodules.i2c1 = bitbang.I2CMaster(platform.request("i2c1"))
        #self.add_csr("i2c1")  


		#serialA
		from litex.soc.cores import uart
		self.submodules.uart1_phy = uart.UARTPHY(
			pads     = platform.request("uart1"),
			clk_freq = self.sys_clk_freq,
			baudrate = 9600)
		self.submodules.uart1 = ResetInserter()(uart.UART(self.uart1_phy,
			tx_fifo_depth = 16,
			rx_fifo_depth = 16))
		self.csr.add("uart1_phy", use_loc_if_exists=True)
		self.csr.add("uart1", use_loc_if_exists=True)
		if hasattr(self.cpu, "interrupt"):
			self.irq.add("uart1", use_loc_if_exists=True)
		else:
			self.add_constant("UART_POLLING")

		
#Boot

		self.add_rom("bootrom", 0x20000000, 2**10, contents = get_mem_data("firmware/firmware.bin", endianness="little"))# "little" for the default RISCV architectures selected by litex
		self.add_constant("ROM_BOOT_ADDRESS", 0x20000000)
			


# Build --------------------------------------------------------------------------------------------


if __name__ == "__main__":
	builder = Builder(BaseSoC(),csr_csv="Soc_MemoryMap.csv")
	builder.build()

