`timescale 1ns / 1ps

module arithmetic #(
    parameter DATA_WIDTH = 32
)(
    input logic clk,
    input logic rst,
    
    input logic [DATA_WIDTH - 1:0] lhs, // rs1 value
    input logic [DATA_WIDTH - 1:0] rhs, // rs2 value or decoded immediate
    
    input logic [14:12] operation, // funct3
    input logic [31:25] metadata, // funct7, or imm[11:5] if applicable (otherwise zero)
    
    output logic [DATA_WIDTH -1:0] result,
    output logic valid
);
    
    always_comb begin
        unique case ({operation, metadata})
            // RV32I operations
            { 3'h0, 7'h00 } : begin result = lhs +  rhs; valid = '1; end
            { 3'h0, 7'h20 } : begin result = lhs -  rhs; valid = '1; end
            { 3'h4, 7'h00 } : begin result = lhs ^  rhs; valid = '1; end
            { 3'h6, 7'h00 } : begin result = lhs |  rhs; valid = '1; end
            { 3'h7, 7'h00 } : begin result = lhs &  rhs; valid = '1; end
            { 3'h1, 7'h00 } : begin result = lhs << rhs; valid = '1; end
            { 3'h5, 7'h00 } : begin result = lhs >> rhs; valid = '1; end
            { 3'h5, 7'h20 } : begin result = $signed(lhs) >>> rhs; valid = '1; end
            { 3'h2, 7'h00 } : begin result = ($signed(lhs) < $signed(rhs)) ? DATA_WIDTH'(1) : DATA_WIDTH'(0); valid = '1; end
            { 3'h3, 7'h00 } : begin result = (lhs < rhs) ? DATA_WIDTH'(1) : DATA_WIDTH'(0); valid = '1; end
            
            default : begin result = 'X; valid = '0; end
        endcase
    end
    
endmodule
