#include "uart1.h"
#include <irq.h>
#include <generated/csr.h>

void uart1_init(void)
{
	uart1_ev_pending_write(uart1_ev_pending_read());
	uart1_ev_enable_write(UART1_EV_TX | UART1_EV_RX);
//	irq_setmask(irq_getmask() | (1 << UART1_INTERRUPT));
}



void uart1_isr(void)
{

}

char uart1_read(void)
{
/*se bloquea si no hay lectura debe esperar dato de lo contrario el procesador se bloquea*/
	char c;
	while (uart1_rxempty_read());
	c = uart1_rxtx_read();
	uart1_ev_pending_write(UART1_EV_RX);
	return c;
}

int uart1_read_nonblock(void)
{
	return (uart1_rxempty_read() == 0);
}

void uart1_write(char c)
{
	while (uart1_txfull_read());
	uart1_rxtx_write(c);
	uart1_ev_pending_write(UART1_EV_TX);
}

void send_string(char s[])
{

	int i=0;

	while (s[i]!= 0x00)
	{

		uart1_write(s[i]);
		i++;

	}


}


void uart1_sync(void)
{
	while (uart1_txfull_read());
}
