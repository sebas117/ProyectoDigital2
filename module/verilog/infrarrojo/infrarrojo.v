`timescale 1ns / 1ps



module infrarrojo(

    input infrarrojo,
    input control_banda,
    output  out_infra,
    output  motor

    );
    
    
    assign out_infra = infrarrojo;
    assign motor= control_banda;
    
endmodule
