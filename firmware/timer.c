#include "delay.h"
#include <generated/csr.h>

void timer_init_irq(unsigned int ms)
{

	timer0_en_write(0);
	timer0_reload_write(0);
	uint32_t tm=(ms*CONFIG_CLOCK_FREQUENCY)/1000;
	timer0_load_write(tm);
	timer0_reload_write(tm);
	timer0_en_write(1);

	timer0_update_value_write(1);

    timer0_ev_pending_write(timer0_ev_pending_read());
	timer0_ev_enable_write(1);
	irq_setmask(irq_getmask() | (1 << TIMER0_INTERRUPT));

}

void timer_isr(){

	
	uint32_t sl =leds_out_read();
	leds_out_write(~sl);
 	timer0_ev_pending_write(1);
	
}
