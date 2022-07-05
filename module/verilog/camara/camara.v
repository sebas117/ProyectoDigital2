`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:14:22 12/02/2019 
// Design Name: 
// Module Name:    cam_read 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module camara(
		//Entradas del test cam
	    input  clk,           	// Board clock: 100 MHz Nexys4DDR.
    	input  rst,	 	// Reset button. Externo


		// Salida
		output  VGA_Hsync_n,  // Horizontal sync output.
		output  VGA_Vsync_n,  // Vertical sync output.
		output  [3:0] VGA_R,  // 4-bit VGA red output.
		output  [3:0] VGA_G,  // 4-bit VGA green output.
		output  [3:0] VGA_B,  // 4-bit VGA blue output.


		//CAMARA input/output conexiones de la camara al modulo principal ********************************

		output  CAM_xclk,		// System  clock input de la cï¿½mara.
		output  CAM_pwdn,		// Power down mode.
		input  CAM_pclk,		// Sennal PCLK de la camara. 
		input  CAM_href,		// Sennal HREF de la camara. 
		input  CAM_vsync,		// Sennal VSYNC de la camara.
		input  [7:0]CAM_px_data,
		
/*		input init,
	    output done,
	    output [2:0]res*/
		
		
		// Mapa de memoria
			// entradas
		input init_procesamiento,
	 		//salidas
		
		output [1:0] color, // 1: Rojo, 2:Green, 3:Blue
		output [1:0] figure, // 1: Triángulo, 2: Círculo, 3: cuadrado
		output    done
    
		   );


	// TAMANO DE ADQUISICION DE LA CAMARA
	// Tamano de la imagne QQVGA

	parameter CAM_SCREEN_X = 160; 		// 640 / 4. Elegido por preferencia, menos memoria usada.
	parameter CAM_SCREEN_Y = 120;    	// 480 / 4.

	localparam DW=12; // Se determina de acuerdo al tamaño de la data, formaro RGB444 = 12 bites.
    localparam AW=15;
	// conexiondes del Clk
	wire clk100M;           // Reloj de un puerto de la Nexys 4 DDR entrada.
	wire clk25M;	// Para guardar el dato del reloj de la Pantalla (VGA 680X240 y DP_RAM).
	wire clk24M;		// Para guardar el dato del reloj de la camara.

	// Conexion dual por ram
	localparam imaSiz= CAM_SCREEN_X*CAM_SCREEN_Y;// Posición n+1 del tamañp del arreglo de pixeles de acuerdo al formato.

	wire [AW-1: 0] DP_RAM_addr_in;		// Conexión  Direccion entrada.
	wire [DW-1: 0] DP_RAM_data_in;      	// Conexion Dato entrada.
	wire DP_RAM_regW;			// Enable escritura de dato en memoria .

	reg  [AW-1: 0] DP_RAM_addr_out;		//Registro de la dirección de memoria. 

	// Conexion VGA Driver
	wire [DW-1:0] data_mem;	    		// Salida de dp_ram al driver VGA
	wire [DW-1:0] data_RGB444;  		// salida del driver VGA a la pantalla
	wire [9:0] VGA_posX;			// Determinar la posición en X del pixel en la pantalla 
	wire [9:0] VGA_posY;			// Determinar la posición de Y del pixel en la pantalla


	/* ****************************************************************************
	Asignación de la información de la salida del driver a la pantalla
	del regisro data_RGB444
	**************************************************************************** */
	assign VGA_R = data_RGB444[11:8]; 	//los 4 bites más significativos corresponden al color ROJO (RED) 
	assign VGA_G = data_RGB444[7:4];  	//los 4 bites siguientes son del color VERDE (GREEN)
	assign VGA_B = data_RGB444[3:0]; 	//los 4 bites menos significativos son del color AZUL(BLUE)


	/* ****************************************************************************
	Asignacion de las seales de control xclk pwdn y reset de la camara
	**************************************************************************** */

	assign CAM_xclk = clk24M;		// AsignaciÃ³n reloj cÃ¡mara.
	assign CAM_pwdn = 0;			// Power down mode.
	

	/* ****************************************************************************
	Se uso "IP Catalog >FPGA Features and Desing > Clocking > Clocking Wizard"  y general el ip con Clocking Wizard
	el bloque genera un reloj de 25Mhz usado para el VGA  y un reloj de 24 MHz
	utilizado para la camara , a partir de una frecuencia de 100 Mhz que corresponde a la Nexys 4
	**************************************************************************** */


	clk24_25_nexys4 clk25_24(
  .CLK_IN1(clk),
  .CLK_OUT1(clk25M),
  .CLK_OUT2(clk24M),
  .RESET(rst)
 );



	/*
	clk24_25_nexys4_0 clk25_24(
	.CLK_IN1(clk),				//Reloj de la FPGA.
	.CLK_OUT1(clk25M),			//Reloj de la VGA.
	.CLK_OUT2(clk24M),			//Reloj de la c�mara.
	.RESET(rst)					//Reset.
	);
	*/
	/* ****************************************************************************
	Modulo de captura de datos /captura_de_datos_downsampler = cam_read
	**************************************************************************** */
//wire done_read;	
	

	cam_read #(AW,DW) cam_read
	(
			.CAM_px_data(CAM_px_data),
			.CAM_pclk(CAM_pclk),
			.CAM_vsync(CAM_vsync),
			.CAM_href(CAM_href),
			.rst(rst),
			

		//outputs
		    //.done(done_read),
			.DP_RAM_regW(DP_RAM_regW),        //enable
			.DP_RAM_addr_in(DP_RAM_addr_in),
			.DP_RAM_data_in(DP_RAM_data_in)

		);

/******************************************************************************
En esta parte se agrega el m�dulo de procesamiento

*******************************************************************************/

wire [AW-1:0]proc_addr_in;
wire [DW-1:0]proc_data_in;

procesamiento my_procesamiento(
		//entradas
		.clk(clk),
		.rst(rst),
		.proc_addr_in(proc_addr_in), 		// Dirección entrada dada por el Buffer.
	    .proc_data_in(proc_data_in),		// Datos que salen del Buffer.
	    
	
	    // Mapa de memoria
	    
	    //Entradas
	    .init_procesamiento(init_procesamiento),
	    //salidas
	    .color(color),
	    .figure(figure),
	    .done(done)
	    
   );



	/* ****************************************************************************
	buffer_ram_dp buffer memoria dual port y reloj de lectura y escritura separados
	Se debe configurar AW  segn los calculos realizados en el Wp01
	se recomiendia dejar DW a 8, con el fin de optimizar recursos  y hacer RGB 332
	**************************************************************************** */

	buffer_ram_dp DP_RAM(
		// Entradas.
		
		.clk_w(CAM_pclk),				// Frecuencia de toma de datos de cada pixel.
		.addr_in(DP_RAM_addr_in), 		// Direccion entrada dada por el capturador.
		.data_in(DP_RAM_data_in),		// Datos que entran de la camara.
		.regwrite(DP_RAM_regW), 	       	// Enable.
		.clk_r(clk25M), 				// Reloj VGA.
		.addr_out(DP_RAM_addr_out),		// Direccion salida dada por VGA.
			// Salida.
			
		.data_out(data_mem),			    // Datos enviados a la VGA.
		//.reset(rst)                   //(Sin usar)
		
	// Salidas procesador
	    //.init(init),
		.proc_data_in(proc_data_in),
    	.proc_addr_in(proc_addr_in)
	);

	/* ****************************************************************************
	VGA_Driver640x480
	**************************************************************************** */
	VGA_Driver VGA_640x480 // Necesitamos otro driver.
	(
		.rst(rst),
		.clk(clk25M), 				// 25MHz  para 60 hz de 160x120.
		.pixelIn(data_mem), 		// Entrada del valor de color  pixel RGB 444.
		.pixelOut(data_RGB444),		// Salida de datos a la VGA. (Pixeles). 
		.Hsync_n(VGA_Hsync_n),		// Sennal de sincronizacion en horizontal negada para la VGA.
		.Vsync_n(VGA_Vsync_n),		// Sennal de sincronizacion en vertical negada  para la VGA.
		.posX(VGA_posX), 			// Posicion en horizontal del pixel siguiente.
		.posY(VGA_posY) 			// posicinn en vertical  del pixel siguiente.

	);
	

	
/*Analyzer Analyzer(
	.data(proc_data_in),
	.clk(clk25M),
	.init(done_read),
	.init_proc(init),
	.addr(proc_addr_in),
	.done(done),
	.res(res)
    );	
*/

	/* ****************************************************************************
	Logica para actualizar el pixel acorde con la buffer de memoria y el pixel de
	VGA si la imagen de la camara es menor que el display VGA, los pixeles
	adicionales seran iguales al color del ultimo pixel de memoria.
	**************************************************************************** */
	always @ (VGA_posX, VGA_posY) begin
			if ((VGA_posX>CAM_SCREEN_X-1)|(VGA_posY>CAM_SCREEN_Y-1))
				//Posicion n+1(160*120), en buffer_ram_dp.v se le asigna el color negro.
				DP_RAM_addr_out = imaSiz;
			else
				DP_RAM_addr_out = VGA_posX + VGA_posY * CAM_SCREEN_X;// Calcula posicion.
	end


endmodule