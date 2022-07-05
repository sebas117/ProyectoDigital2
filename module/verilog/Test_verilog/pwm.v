`timescale 1ns / 1ps



module pwm(
    input enable,
    input [31:0] period,
    input [31:0] dutty,
    input clk,
    output reg pwm
    );

reg[27:0] counter=28'd0;
reg[15:0] limite;
reg[15:0] activo;

always @(posedge clk) begin

counter <= counter + 28'd1;

     if(counter>=(period-1))
        counter <= 28'd0;

     if(counter <= dutty)
        pwm <= 1;
        else
        pwm <=0;

end

endmodule