`timescale 1ns / 1ps

module spartan_fpga_cpu(
    input logic clk,
    input logic rst_raw_n,
    
    output logic led_out
);
    logic rst;
    reset_synchronizer reset_synchronizer (
        .clk ( clk ),
        .rst_async ( !rst_raw_n ), // button is active-low
        
        .rst_out ( rst )
    );
    
    five_cycle_cpu cpu (
        .clk ( clk ),
        .rst ( rst ),
        
        .led_out ( led_out )
    );
endmodule
