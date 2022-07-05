from migen import *
from migen.genlib.cdc import MultiReg
from litex.soc.interconnect.csr import *
from litex.soc.interconnect.csr_eventmanager import *

# Modulo Principal
class Infrarrojo(Module,AutoCSR):
    def __init__(self, infrarrojo, motor):
    
        self.infrarrojo = infrarrojo
        self.motor = motor
        


        #Mapa de memoria 
        #Registro de lectura 

        self.out_infra = CSRStatus(1)

        #Registro de escritura
        self.control_banda = CSRStorage(1)
  
         

        self.specials +=Instance("infrarrojo",

            i_infrarrojo = self.infrarrojo,
            i_control_banda = self.control_banda.storage,
            o_out_infra = self.out_infra.status,
            o_motor = self.motor,   

            
        )
