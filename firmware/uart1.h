#ifndef __UART1_H
#define __UART1_H

#ifdef __cplusplus
extern "C" {
#endif

#define UART1_EV_TX	0x1
#define UART1_EV_RX	0x2

void uart1_init(void);
void uart1_isr(void);
void uart1_sync(void);

void uart1_write(char c);
char uart1_read(void);
int uart1_read_nonblock(void);

#ifdef __cplusplus
}
#endif

#endif
