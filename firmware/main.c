#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <irq.h>
#include <uart.h>
#include <console.h>
#include <generated/csr.h>
#include <string.h>



#include "delay.h"
#include "display.h"
#include "camara.h"
#include "uart1.h"

unsigned short color_actual=0;
int rojo = 0;
int verde = 0;
int azul = 0;
#define MAXIMA_LONGITUD_CADENA 100

static char *readstr(void)
{
	char c[2];
	static char s[64];
	static int ptr = 0;

	if(readchar_nonblock()) {
		c[0] = readchar();
		c[1] = 0;
		switch(c[0]) {
			case 0x7f:
			case 0x08:
				if(ptr > 0) {
					ptr--;
					putsnonl("\x08 \x08");
				}
				break;
			case 0x07:
				break;
			case '\r':
			case '\n':
				s[ptr] = 0x00;
				putsnonl("\n");
				ptr = 0;
				return s;
			default:
				if(ptr >= (sizeof(s) - 1))
					break;
				putsnonl(c);
				s[ptr] = c[0];
				ptr++;
				break;
		}
	}
	return NULL;
}

static char *get_token(char **str)
{
	char *c, *d;

	c = (char *)strchr(*str, ' ');
	if(c == NULL) {
		d = *str;
		*str = *str+strlen(*str);
		return d;
	}
	*c = 0;
	d = *str;
	*str = c+1;
	return d;
}

static void prompt(void)
{
	printf("RUNTIME>");
}

static void help(void)
{
	puts("Available commands:");
	puts("help                            - this command");
	puts("reboot                          - reboot CPU");
	puts("led                             - led test");
	puts("switch                          - switch test");
	puts("display                         - display test");
	puts("rgbled                          - rgb led test");
	//puts("vga                           - vga test");
	puts("camara                          - camara test");
	puts("pwm			                  - pwm test");
	puts("uart1                           - uart1 test");
	puts("infrarrojo                       -infra_test");
	puts("banda		                       -banda_test");
}

static void reboot(void)
{
	ctrl_reset_write(1);
}

static void display_test(void)
{
	int i;
	signed char defill = 0;	//1->left, -1->right, 0->.
	
	char txtToDisplay[40] = {0, DISPLAY_0, DISPLAY_1,DISPLAY_2,DISPLAY_3,DISPLAY_4,DISPLAY_5,DISPLAY_6,DISPLAY_7,DISPLAY_8,DISPLAY_9,DISPLAY_A,DISPLAY_B,DISPLAY_C,DISPLAY_D,DISPLAY_E,DISPLAY_F,DISPLAY_G,DISPLAY_H,DISPLAY_I,DISPLAY_J,DISPLAY_K,DISPLAY_L,DISPLAY_M,DISPLAY_N,DISPLAY_O,DISPLAY_P,DISPLAY_Q,DISPLAY_R,DISPLAY_S,DISPLAY_T,DISPLAY_U,DISPLAY_V,DISPLAY_W,DISPLAY_X,DISPLAY_Y,DISPLAY_Z,DISPLAY_DP,DISPLAY_TR,DISPLAY_UR};
	
	printf("Test del los display de 7 segmentos... se interrumpe con el botton 1\n");

	while(!(buttons_in_read()&1)) {
		display(txtToDisplay);
		if(buttons_in_read()&(1<<1)) defill = ((defill<=-1) ? -1 : defill-1);
		if(buttons_in_read()&(1<<2)) defill = ((defill>=1) ? 1 : defill+1);
		if (defill > 0) {
			char tmp = txtToDisplay[0];
			for(i=0; i<sizeof(txtToDisplay)/sizeof(txtToDisplay[i]); i++) {
				txtToDisplay[i] = ((i==sizeof(txtToDisplay)/sizeof(txtToDisplay[i])-1) ? tmp : txtToDisplay[i+1]);
			}
		}
		else if(defill < 0) {
			char tmp = txtToDisplay[sizeof(txtToDisplay)/sizeof(txtToDisplay[0])-1];
			for(i=sizeof(txtToDisplay)/sizeof(txtToDisplay[i])-1; i>=0; i--) {
				txtToDisplay[i] = ((i==0) ? tmp : txtToDisplay[i-1]);
			}
		}
		delay_ms(500);
	}
}

static void led_test(void)
{
	unsigned int i;
	printf("Test del los leds... se interrumpe con el botton 1\n");
	while(!(buttons_in_read()&1)) {

	for(i=1; i<65536; i=i*2) {
		leds_out_write(i);
		delay_ms(50);
	}
	for(i=32768;i>1; i=i/2) {
		leds_out_write(i);
		delay_ms(50);
	}
	}
	
}


static void switch_test(void)
{
	unsigned short temp2 =0;
	printf("Test del los interruptores... se interrumpe con el botton 1\n");
	while(!(buttons_in_read()&1)) {
		unsigned short temp = switchs_in_read();
		if (temp2 != temp){
			printf("switch bus : %i\n", temp);
			leds_out_write(temp);
			temp2 = temp;
		}
	}
}

static void rgbled_test(void)
{
	unsigned int T = 128;
	
	ledRGB_1_r_period_write(T);
	ledRGB_1_g_period_write(T);
	ledRGB_1_b_period_write(T);

	ledRGB_1_r_enable_write(1);
	ledRGB_1_g_enable_write(1);
	ledRGB_1_b_enable_write(1);

	
	ledRGB_2_r_period_write(T);
	ledRGB_2_g_period_write(T);
	ledRGB_2_b_period_write(T);
	
	
	ledRGB_2_r_enable_write(1);
	ledRGB_2_g_enable_write(1);
	ledRGB_2_b_enable_write(1);

	for (unsigned int j=0; j<100; j++){
		ledRGB_1_g_width_write(j);
		for (unsigned int i=0; i<100; i++){
			ledRGB_1_r_width_write(100-i);
			ledRGB_1_b_width_write(i);	
			delay_ms(20);

		}	
	}
	


}


/* static void vga_test(void)
{
	int x,y;
	
	for(y=0; y<480; y++) {
		for(x=0; x<640; x++) {
			vga_cntrl_mem_we_write(0);
			vga_cntrl_mem_adr_write(y*640+x);
			if(x<640/3)	
				vga_cntrl_mem_data_w_write(((int)(x/10)%2^(int)(y/10)%2)*15);
			else if(x<2*640/3) 
				vga_cntrl_mem_data_w_write((((int)(x/10)%2^(int)(y/10)%2)*15)<<4);
			else 
				vga_cntrl_mem_data_w_write((((int)(x/10)%2^(int)(y/10)%2)*15)<<8);
			vga_cntrl_mem_we_write(1);
		}
	}
} */

static void camara_test(void)
{
	unsigned short figura=0;
	unsigned short color=0;
	unsigned short done=0;	
	
		
	printf("Hola mundo");
		
	while(!(buttons_in_read()&1)) {

        camara_cntrl_init_procesamiento_write(1);
        delay_ms(2);
        camara_cntrl_init_procesamiento_write(0);
		delay_ms(2);

		done=camara_cntrl_done_read();
		figura=camara_cntrl_figure_read();
		color=camara_cntrl_color_read();
		
		
		
		printf("Done : %i\n", done); 

		if(figura==1) 
			printf("Triangulo\n");
		else if(figura==2) 
			printf("Circulo\n");
		else if(figura==3) 
			printf("Cuadrado\n");
		else if(figura==0) 
			printf("Figura no definida\n");

		if(color==1) 
			printf("Rojo\n");
		else if(color==2) 
			printf("Verde\n");
		else if(color==3) 
			printf("Azul\n");
		else if(color==0) 
			printf("Color no definido\n");
			
		delay_ms(2000);
	} 
}


static void camara(void)
{	
	
	unsigned short figura=0;
	unsigned short color=0;
	unsigned short done=0;	

	char message[] = {"Procesamiento Camara: "};
	char cuadrado[] = {"Cuadrado\n"};
	char _rojo[] = {"Rojo\n"};
	char _verde[] = {"Verde\n"};
	char _azul[] = {"Azul\n"};	
	char _descon[] = {"Desconocido\n"};


        camara_cntrl_init_procesamiento_write(1);
        delay_ms(2);
        camara_cntrl_init_procesamiento_write(0);
		delay_ms(2);

		done=camara_cntrl_done_read();
		figura=camara_cntrl_figure_read();
		color=camara_cntrl_color_read();
		
		
		send_string(message); uart1_write('\n');


		printf("Done : %i\n", done); 

		if(figura==1) {
			printf("Triangulo\n");
			}
		else if(figura==2) {
			printf("Circulo\n");
			}
		else if(figura==3) {
			printf("Cuadrado\n");
			send_string(cuadrado);

			 }
		else if(figura==0) {
			printf("Figura no definida\n");
			
			}

		if(color==1) {
			printf("Rojo\n");
			send_string(_rojo);
			rojo++;
			 }
		else if(color==2) {
			printf("Verde\n");
			send_string(_verde);
			verde++;
			}
		else if(color==3) {
			printf("Azul\n");
			send_string(_azul);
			azul++;
			}
		else if(color==0) {
			printf("Color no definido\n");
			send_string(_descon);
			 }

			 color_actual = color;


		uart1_write('\n');
		uart1_write('\n');
			
		//delay_ms(2000);
	 
}






 static void test_ir(void){
	while(!(buttons_in_read()&1)) {
		leds_out_write(infra_cntrl_out_infra_read());
		delay_ms(50);
		}

} 


//Pwm Test2
//600 = 0 grados
//1575 = 90 grados
//2550 = 180 grados
//+325 = 30 grados

static void pwm_iz(void){

	unsigned int period = 20000; //(20ms)
	unsigned int dutty_centro = 1550; //1575 = 90 grados
	unsigned int dutty_izq = 1165;    //1250 = -30 grados



	pwm_cntrl_period_write(period);
	pwm_cntrl_dutty_write(dutty_izq);
	delay_ms(1000);	
				
	pwm_cntrl_period_write(period);
	pwm_cntrl_dutty_write(dutty_centro);
	delay_ms(1000);	


}


static void pwm_der(void){

	unsigned int period = 20000; //(20ms)
    unsigned int dutty_centro = 1550; //1575 = 90 grados
	unsigned int dutty_der =  1900;   //1900 = +30 grados


	pwm_cntrl_period_write(period);
	pwm_cntrl_dutty_write(dutty_der);
	delay_ms(1000);	
				
	pwm_cntrl_period_write(period);
	pwm_cntrl_dutty_write(dutty_centro);
	delay_ms(1000);	


}



static void pwm_test(void)
{
	unsigned int period = 20000; //(20ms)
	int dutty = 0;
	unsigned int enable = 1;
	unsigned int disable = 0;

	unsigned int dutty_centro = 1550; //1575 = 90 grados
	unsigned int dutty_der =  1900;   //1900 = +30 grados
	unsigned int dutty_izq = 1165;    //1250 = -30 grados

	pwm_cntrl_enable_write(enable);
	printf("Test de pwm ... se interrumpe con el boton 1\n");
	
	delay_ms(10);

	

							
/* 	pwm_cntrl_period_write(period);
	pwm_cntrl_dutty_write(dutty_centro);
	delay_ms(1000);	 */

/* 	dutty = 1900;						
	pwm_cntrl_period_write(period);
	pwm_cntrl_dutty_write(dutty_der);
	delay_ms(1000); */

	dutty = 1250;						
	pwm_cntrl_period_write(period);
	pwm_cntrl_dutty_write(dutty_izq);
	delay_ms(1000);	
				
	pwm_cntrl_period_write(period);
	pwm_cntrl_dutty_write(dutty_centro);
	delay_ms(1000);	

/* 						
	pwm_cntrl_period_write(period);
	pwm_cntrl_dutty_write(dutty_centro);
	delay_ms(1000);	 */
	
	
    pwm_cntrl_enable_write(disable);
	
	
}

static void pwm(void)
{	

	unsigned int enable = 1;
	unsigned int disable = 0;

	pwm_cntrl_enable_write(enable);
	
	switch (color_actual)
	{
	case 1:
		
			pwm_iz(); //Color Rojo Invalido

		break;

	case 2: 

			pwm_der(); //Color Verde Valido
			break;

	case 3: 

			pwm_iz(); //Color Azul Invalido
			break;	
	default:

			pwm_iz(); //Color Invalido

		break;
	}
	
    pwm_cntrl_enable_write(disable);
	
	
}



static void uart1_test(void)
{
	printf("Test de la uart 1, debe poner en corto el pon RX Tx de la la UART1.\n");
	
	printf("se envia el caracter A por la uart 1  y al estar en loopback se recibe el caracter  y se retrasmite por la uart 0\n");
	printf("se interrumpe con el botton 1\n");
	
	while(!(buttons_in_read()&1)) {
		uart1_write('H');
		delay_ms(50);
		uart_write(uart1_read());
		}




}




static void imprimir_info(void){

char r[]={""};
char g[]={""};
char b[]={""};

char message[] = {"Informacion de la banda: \n\n"};
char n_rojo[] = {"#Rojo: "};
char n_verde[] = {"#Verde: "};
char n_azul[] = {"#Azul: "};



send_string(message);

send_string(n_rojo); sprintf(r, "%d", rojo); send_string(r);  uart1_write('\n');
send_string(n_verde); sprintf(g, "%d", verde); send_string(g);  uart1_write('\n');
send_string(n_azul); sprintf(b, "%d", azul); send_string(b);  uart1_write('\n');

uart1_write('\n');
uart1_write('\n');

}



static void banda_test(void)
{
	int func = 0; 
	int unsigned infra;
	int unsigned motor; 
	int unsigned registro;
	int i;
	char c;


	imprimir_info();


    while(!(buttons_in_read()&1) /* & func!='2'  */) {

		//func = uart1_read();
		//Avanzar()
		
		//func = uart1_rxtx_read();
		infra = infra_cntrl_out_infra_read(); 

		
		infra_cntrl_control_banda_write(1); //Avanzar()

		if(!infra){

			delay_ms(600);
			

			//infra_cntrl_control_banda_write(0);

		
			camara();
			imprimir_info();

			
			//infra_cntrl_control_banda_write(1);

			delay_ms(1400);
			//infra_cntrl_control_banda_write(0);
			pwm();
			



		}
		
		}

		infra_cntrl_control_banda_write(0);

}


static void banda_off(void){

	infra_cntrl_control_banda_write(0);

}


static void console_service(void)
{
	char *str;
	char *token;

	str = readstr();
	if(str == NULL) return;
	token = get_token(&str);
	if(strcmp(token, "help") == 0)
		help();
	else if(strcmp(token, "reboot") == 0)
		reboot();
	else if(strcmp(token, "led") == 0)
		led_test();
	else if(strcmp(token, "switch") == 0)
		switch_test();
	else if(strcmp(token, "display") == 0)
		display_test();
	else if(strcmp(token, "rgbled") == 0)
		rgbled_test();
	//else if(strcmp(token, "vga") == 0)
		//vga_test();
	else if(strcmp(token, "camara") == 0)
		camara_test();
	else if(strcmp(token, "pwm") == 0)
		pwm_test();
	else if(strcmp(token, "uart1") == 0)
		uart1_test();
	else if(strcmp(token, "infrarrojo") == 0)
		test_ir();
	else if(strcmp(token, "banda") == 0)
		banda_test();
	prompt();
}

int main(void)
{
	int func = 0;

	irq_setmask(0);
	irq_setie(1);
	uart_init();
	uart1_init(); //Comunicacion BT 
    camara_init();



	//timer_init_irq(1000);
    
    puts("\n                     Prueba Inicial para Proyecto                  \n");
	puts("\nSoC - RiscV project UNAL 2022-1-- CPU testing software built "__DATE__" "__TIME__"\n");
	help();
	prompt();

	while(1) {
		func = uart1_read();
		uart_write(func);

		if(func == '1')
	        banda_test();
		if(func == '2')
	        banda_off();.
			

	}

	return 0;
}
