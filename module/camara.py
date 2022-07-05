from migen import *
from migen.genlib.cdc import MultiReg
from litex.soc.interconnect.csr import *
from litex.soc.interconnect.csr_eventmanager import *

# Modulo Principal
class Camara(Module,AutoCSR):
    def __init__(self, VGA_Vsync_n ,VGA_Hsync_n, VGA_R, VGA_G, VGA_B, xclk, CAM_pwdn, pclk,cam_data_in, vsync, href):
        
        self.clk = ClockSignal() #Reloj global   
        self.rst = ResetSignal() #Reset Global


        #VGA

        self.VGA_Vsync_n= VGA_Vsync_n #Sincronizacion vertical
        self.VGA_Hsync_n= VGA_Hsync_n #Sincronizacion horizontal
        self.VGA_R= VGA_R 
        self.VGA_G= VGA_G
        self.VGA_B= VGA_B

        #Camara

        self.xclk = xclk  #Señal de 24 MHz
        self.CAM_pwdn = CAM_pwdn
        self.pclk = pclk   #Reloj de los datos
        self.href = href
        self.vsync = vsync
        self.px_data = cam_data_in #datos de la cámara


        #Mapa de memoria 
            #Registros de lectura (RO)

        self.color = CSRStatus(2) #1: Rojo, 2: Green, 3: Blue
        self.figure = CSRStatus(2) # 1: Triangulo, 2: Círculo, 3: Cuadrado
        self.done = CSRStatus() # Registro de lectura de 1 bit. Read

            #Registro de escritura /lectura

        self.init_procesamiento = CSRStorage() # Iniciar procesamiento con 1 bit

        # En esta parte se pasa de Python a Verilog
        # i_: Entrada
        # o_: Salida
        # CSR Registro de Control y Estatus


        self.specials +=Instance("camara",
            i_clk = self.clk,
            i_rst = self.rst,

            o_VGA_Hsync_n=self.VGA_Hsync_n,
            o_VGA_Vsync_n=self.VGA_Vsync_n,
            o_VGA_R=self.VGA_R,  
            o_VGA_G=self.VGA_G,
            o_VGA_B=self.VGA_B,

            # Camara
            
            o_CAM_xclk = self.xclk,
            o_CAM_pwdn=self.CAM_pwdn,
            i_CAM_pclk = self.pclk,
            i_CAM_href = href,        
            i_CAM_vsync = vsync,
            i_CAM_px_data=self.px_data,

            # Mapa de memoria
                # entradas
            i_init_procesamiento=self.init_procesamiento.storage,
	         	#salidas
		    o_color=self.color.status, # 1: Rojo, 2:Green, 3:Blue
		    o_figure=self.figure.status, # 1: Triángulo, 2: Círculo, 3: cuadrado
		    o_done=self.done.status,
        )
        
        
       
        self.submodules.ev = EventManager()
        self.ev.ok = EventSourceProcess()
        self.ev.finalize()
 
        self.ev.ok.trigger.eq(self.done.status)
