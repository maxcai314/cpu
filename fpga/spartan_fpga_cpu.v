`timescale 1ns / 1ps

// a five-cycle pipelined cpu
module spartan_fpga_cpu (
    input wire clk,
    input wire rst,
    
    output wire led_out
);
    
    five_cycle_cpu five_cycle_cpu (
        .clk ( clk ),
        .rst ( rst ),
        
        .led_out ( led_out )
    );

endmodule