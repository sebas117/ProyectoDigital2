from migen import *
from migen.genlib.cdc import MultiReg
from litex.soc.interconnect.csr import *
from litex.soc.interconnect.csr_eventmanager import *

# Modulo Principal
class Pwm(Module,AutoCSR):
    def __init__(self, pwm):
    
        self.clk = ClockSignal() 
        self.enable = CSRStorage(1)
        self.period = CSRStorage(32) 
        self.dutty = CSRStorage(32)  
        self.pwm = pwm
         

        self.specials +=Instance("pwm",
            i_clk = self.clk,
            i_enable = self.enable.storage,
            i_period = self.period.storage,
            i_dutty = self.dutty.storage,
            o_pwm=self.pwm,
        )
