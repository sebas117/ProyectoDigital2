`timescale 1ns / 1ps



module pwm(
    input enable,
    input [31:0] period,   // microsegundos
    input [31:0] dutty,    //microsegundos 
    input clk,
    output reg pwm = 0
    );

reg[23:0] counter=23'd0; //contador para generar el clk_1M
reg [31:0] countera =31'd0; //contador para el pwm
reg clk_1M;



reg rst_counteraa=0;


initial begin

counter = 0;
clk_1M= 0;
countera =0;

end

//Divisor de frecuencia
always @(posedge clk) begin

    if(counter == 50) begin  //Compara el valor del contador con el contador maximo

        clk_1M = ~clk_1M;
        counter =0;
    end

    else begin

    counter = counter +1;

    end

end

//Bloque contador

always @(posedge clk_1M) begin

    if(rst_counteraa)
    countera <= 0;
    
    else countera = countera +1;

end

//Maquina de estados  
   parameter INITIAL = 2'b00;
   parameter PWM_on = 2'b01;
   parameter PWM_off = 2'b10;
  //parameter <state4> = 2'b11;
  


   reg [1:0] cs = 2'b00;

   always @(negedge clk_1M)

         case (cs)
            INITIAL : begin
            
               rst_counteraa <= 1;
               pwm <= 0;
            
               if (enable)
                  cs <= PWM_on;
               else
                  cs <= INITIAL;
            end
            PWM_on : begin
            
                rst_counteraa <= 0;
                pwm <= 1;
            
               if (countera <= dutty )
                  cs <= PWM_on;
               else
                  cs <= PWM_off;
            end
            
            PWM_off : begin
            
                rst_counteraa <= 0;
                pwm <= 0;
               
               if (countera <= period)
                  cs <= PWM_off;
               else
                  cs <= INITIAL;
            end
            
            default:
                
                    cs <= INITIAL;
            
         endcase

							


endmodule