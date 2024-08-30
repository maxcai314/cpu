`timescale 1ns / 1ps

module arithmetic #(
    parameter DATA_WIDTH = 32,
    localparam bit [DATA_WIDTH - 1:0] ZERO = '0,
    localparam bit [DATA_WIDTH - 1:0] ONE = '1
)(
    input logic clk,
    input logic rst,
    
    input logic [DATA_WIDTH - 1:0] lhs, // rs1 value
    input logic [DATA_WIDTH - 1:0] rhs, // rs2 value or decoded immediate
    
    input logic [14:12] operation, // funct3
    input logic [31:25] metadata, // funct7, or imm[11:5] if applicable (otherwise zero)
    
    output logic [DATA_WIDTH -1:0] result
);
    
    always_comb begin
        unique case ({operation, metadata})
            // RV32I operations
            { 3'h0, 7'h00 } : result = lhs + rhs;
            { 3'h0, 7'h20 } : result = lhs - rhs;
            { 3'h4, 7'h00 } : result = lhs ^ rhs;
            { 3'h6, 7'h00 } : result = lhs | rhs;
            { 3'h7, 7'h00 } : result = lhs & rhs;
            { 3'h1, 7'h00 } : result = lhs << rhs;
            { 3'h5, 7'h00 } : result = lhs >> rhs;
            { 3'h5, 7'h20 } : result = $signed(lhs) >>> rhs;
            { 3'h2, 7'h00 } : result = ($signed(lhs) < $signed(rhs)) ? ONE : ZERO;
            { 3'h3, 7'h00 } : result = (lhs < rhs) ? ONE : ZERO;
        endcase
    end
    
endmodule
