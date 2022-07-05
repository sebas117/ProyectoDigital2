`timescale 10ns / 1ns
module cam_read #(
		    parameter AW = 15,
            parameter DW = 12		// Cantidad de bits  de la dirección 
		    )(

		    input CAM_pclk,             //Entrada CAM_pclk de la cámara
		    input rst,              //Reset de la cámara
		    input CAM_vsync,            //Señal CAM_vsync de la cámara que permite saber cuándo empieza una imagen
		    input CAM_href,             //Señal href de la cámara que permite saber qué línea de píxeles se está escribiendo
		    input [7:0] CAM_px_data,    //Entrada de dato de 8 bits de la cámara(correspondiente a una parte de un píxel)

		    output reg [AW-1:0] DP_RAM_addr_in=0, // Address de la memoria (posición donde se está escribiendo)
		    output reg [DW-1:0]  DP_RAM_data_in, // RGB 444 to RGB444  
		    output reg DP_RAM_regW //  Nos indica si estamos escribiendo en memoria o no

		    
   );
   reg [1:0]cs=0;// Actúa como el contador de case (para establecer los casos)
	 reg ovsync;// Utilizado para guardar el valor pasado de Vsync
	 reg bp=1'b0;
always @ (posedge CAM_pclk) begin// sentencias que se llevan a cabo siempre y cuando CAM_pclk se encuentre en un flanco de subida
	case (cs)//inicio de la máquina de estados
	0: begin// estado 0 de la máquina de estados cs=00
		if(ovsync && !CAM_vsync)begin//rápidamente ovsync ha tomado el primer valor de vsync y procedemos a compararlos, con && garantizamos una comparación de tipo AND
		cs=1;// si ovsync y !vsync =1 entonces procedemos a pasar al case 1
		DP_RAM_addr_in=0;//iniciamos en la posición de memoria 0
		end
        else begin
                 DP_RAM_data_in<=0;
                 DP_RAM_addr_in<=0;
                 DP_RAM_regW<=0;
             end 

	end
	1: begin// primer estado, cs=01, en este caso hacemos la captura de los datos y procedemos a convertirlos a RGB 444
		DP_RAM_regW=0;// indicamos que aún no escribimos en la memoria
		if (CAM_href) begin//debemos asegurar que href se encuentre en flanco de subida para hacer el proceso
/****************************************************************
 En esta parte se asignan los 4 bits menos significativos del primer Byte
 a los 4 bits mas significativos del dato a escribir en memoria  
******************************************************************/
				DP_RAM_data_in[11]=CAM_px_data[3];     //R3     
				DP_RAM_data_in[10]=CAM_px_data[2];     //R2        
				DP_RAM_data_in[9]=CAM_px_data[1];      //R1           
				DP_RAM_data_in[8]=CAM_px_data[0];      //R0        
		
				cs=2;// Después de tomar los datos más significativos pasamos al estado 2 
		end
	end
	2: begin// Estado 2, en este estado procedemos a tomar los datos del color azul(B) que vienen en formato 565 RGB y se pasa a 332 RGB
				DP_RAM_data_in[7:0]=CAM_px_data; // G3,G2,G1,G0 & B3, B2, B1, B0
				
			 	DP_RAM_regW=1;//Procedemos a escribir en memoria
				DP_RAM_addr_in=DP_RAM_addr_in+1;//Nos desplazamos a la siguiente dirección de memoria
				cs=1;//Posteriormente volvemos al estado 1 de la máquina de estados 
		if(CAM_vsync) begin// Con este condicional analizamos si vsync está en un flanco de subida volvemos al estado 0
		cs=0;//volvemos al estado 0 de nuestra máquina de estados
		end		
		if (DP_RAM_addr_in==19200) begin//Limitador de memoria
			DP_RAM_addr_in=0;// Si la memoria  llega  a la posición de  19200 píxeles, debe volver a la posición 0 nuevamente
			cs=0;//Nos devolvemos al estado 0 a evaluar vsync
		end
        //else DP_RAM_addr_in=DP_RAM_addr_in+1;
		end
endcase
	ovsync<=CAM_vsync;// Se usa para que recurrentemente ovsync tome el valor pasado de vsync
end
endmodule