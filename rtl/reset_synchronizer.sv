`timescale 1ns / 1ps

module reset_synchronizer (
    input logic clk,
    input logic rst_async,
    
    output logic rst_out
);
    logic rst_staged; // prevent metastability
    
    always_ff @(posedge clk) begin
        rst_staged <= rst_async;
        rst_out <= rst_staged;
    end
endmodule
