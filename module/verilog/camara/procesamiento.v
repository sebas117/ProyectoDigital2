`timescale 10ns / 1ns

module procesamiento#(
		parameter n = 120,  // Filas
		parameter m = 160,  // columas
		parameter AW = 15,		 // Cantidad de bits  de la direccion.
	    parameter DW = 12		 // Cantidad de Bits de los datos.
		
		)
		(
		//entradas
		clk,
		rst,
		init_procesamiento,
		proc_addr_in, // Dirección entrada dada por el capturador.
	    proc_data_in, // Datos que entran de la cámara.
	    
	    //salidas
	    color,
	    figure,
	    done
	    
   );
        input clk;
		input rst;
		input init_procesamiento;
		output reg [AW-1: 0] proc_addr_in=15'b1111_1111_1111_111; // Dirección entrada dada por el capturador.
	    input [DW-1: 0] proc_data_in; // Datos que entran de la cámara.
	    
	
		output reg [1:0] color=0; 
		output reg [1:0] figure=0;
		output reg  done=0;
		reg [18:0] R;
		reg [18:0] G;
		reg [18:0] B;
		localparam min_R=0;
		localparam min_G=0;
		localparam min_B=0;

localparam INIT=0,ADD_COL=1,SEL_COL=2,ADD_ACH_MAY=3,DONE_state=4,CARGAR_DATO=5,NOTHING=6, imaSiz=19200;
reg Done_sig=0,Add_Anc_May=0, Sel_Color=0, Add_Columna=0, Cargar_Dato=0, Reset=0;
reg [2:0]status=0;

reg was_init_procesamiento=0; // Habilita volver a procesa
reg aux_init_procesamiento=0; //Guarda la orden de inicio de procesamiento
reg enable=1;
reg [7:0] col=0;
reg [6:0] fil=1;

localparam min_ancho_actual=7;
reg [7:0] ancho_actual=0;
reg [7:0] ancho_anterior=0;
reg [6:0] ancho_mayor=0;
reg [6:0] fila_valida=0;
//reg [6:0] limite_superior=0;
//reg [6:0] limite_inferior=0;

always @(negedge clk) begin
    if(rst|Reset) begin
        color<=0; 
        figure<=0;
        done<=0;
            
        
        
        col<=1;
        fil<=1;
        
        ancho_actual<=0;
        ancho_anterior<=0;
        ancho_mayor<=0;
        fila_valida<=0;
        
        
        R<=0;
        G<=0;
        B<=0;
        
        
        aux_init_procesamiento<=0;
        proc_addr_in<=15'b1111_1111_1111_111;
        
        end
    
        else begin
        if(Cargar_Dato) begin
          proc_addr_in=proc_addr_in+1;
        end
        
        else if(Done_sig) begin
        done<=1;
        
        aux_init_procesamiento<=0;
        // Se hace necesaria la última comparación
        if(ancho_actual>min_ancho_actual)begin 
                fila_valida<=fila_valida+1;
                if(ancho_anterior<ancho_actual)ancho_mayor<=ancho_mayor+1;
            end
        
        // Para el color

        if(R>G&R>B) color<=1; // Color Rojo
        else if(G>R&G>B) color<=2; // Color Verde
        else if(B>R&B>G) color<=3; // Color Azul
        else color<=0;
        
        // Para la Figura
       //fila_valida-(fila_valida>>4) Se hacen 4 corrimiento a derecha lo que equivale al 1/2^2 porciento de error admitido
       //(fila_valida+(fila_valida>>4))>>1 hace referencia al 50 porciento de las filas validas mas un error. 
        if(fila_valida>=ancho_mayor&ancho_mayor>(fila_valida>>1)) figure<=1; // Tri�ngulo
        else if((fila_valida>>1)>=ancho_mayor&ancho_mayor>(fila_valida>>2)) figure<=2; // c�rculo
        else if(fila_valida>0) figure<=3; // cuadrado
        else figure<=0;
        
        end
        
        else if (Add_Anc_May)begin
        fil<=fil+3;
        proc_addr_in<=proc_addr_in+2*m;
        col<=0;
            if(ancho_actual>min_ancho_actual)begin 
                
                fila_valida<=fila_valida+1;
                if(ancho_anterior<ancho_actual)ancho_mayor<=ancho_mayor+1;
            
            end
        ancho_anterior<=ancho_actual;
        ancho_actual<=0;       
        end
        
        else if (Sel_Color)begin
        
   
         ancho_actual<=ancho_actual+1;
         R<=R+proc_data_in[11:8];
        G<=G+proc_data_in[7:4];
        B<=B+proc_data_in[3:0];
        end 
        
        
        else if (Add_Columna)begin
        col<=col+1; 
        end
        
    end        
    
end

always @(posedge clk)begin
    if(rst|Reset)begin
    status<=0;
    Done_sig<=0;
    Add_Anc_May<=0; 
    Sel_Color<=0; 
    Add_Columna<=0; 
    Cargar_Dato<=0;
    Reset<=0;
    enable<=1;
    was_init_procesamiento<=0;
    end
    else begin
     case (status)
         INIT:begin
         Done_sig<=0;
         Add_Anc_May<=0;
         Sel_Color<=0;
         Add_Columna<=0;
         Cargar_Dato<=0;
         
         if((~was_init_procesamiento)|enable)begin
            if(init_procesamiento|enable)begin
               was_init_procesamiento<=1;
               Reset<=0;
               status<=CARGAR_DATO;
               enable<=0;       
            end
         aux_init_procesamiento<=init_procesamiento;
         end
         
         if(~init_procesamiento) Reset<=1;
            
         
         end
         
         CARGAR_DATO:begin 
         Done_sig<=0;
         Add_Anc_May<=0;
         Sel_Color<=0;
         Add_Columna<=0;
         Cargar_Dato<=1;
         
         
         
         if(proc_data_in[11:8]>=min_R|proc_data_in[7:4]>=min_G|proc_data_in[3:0]>=min_B) begin 
         status<=SEL_COL;
         end
         else if(col>=m) begin
         status<=ADD_ACH_MAY;
         end
         else status<=ADD_COL;
         
 
         
         end
         
         SEL_COL: begin
         
         Done_sig<=0;
         Add_Anc_May<=0;
         Sel_Color<=1;
         Add_Columna<=0;
         Cargar_Dato<=0;
         
         if(col>=m)begin
         status<=ADD_ACH_MAY;
         end
         else status<=ADD_COL;
       
         end
         
         ADD_ACH_MAY:begin
         Add_Anc_May<=1;
         Sel_Color<=0;
         Add_Columna<=0;
         Cargar_Dato<=0;
         
         status<=ADD_COL;
         end
         
         ADD_COL:begin 
         Done_sig<=0;
         Add_Anc_May<=0;
         Sel_Color<=0;
         Add_Columna<=1;
         Cargar_Dato<=0;
            
         if(fil>n) status=DONE_state;
         else status=CARGAR_DATO;      
         end
          
         DONE_state:begin
             Done_sig<=1;
             Add_Anc_May<=0;
             Sel_Color<=0;
             Add_Columna<=0;
             Cargar_Dato<=0;
             
             was_init_procesamiento<=0;
         status<=NOTHING;
         end
         
         NOTHING:begin
         
             if(init_procesamiento)begin
                 status<=INIT;
                 enable<=1;
                 Reset<=1;  
              end
             
         end
         
         default: status<=INIT;
    endcase
 end
end
		

endmodule