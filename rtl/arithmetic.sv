`timescale 1ns / 1ps

module arithmetic #(
    parameter DATA_WIDTH = 32
) (
    input logic [DATA_WIDTH - 1:0] lhs, // rs1 value
    input logic lhs_valid,
    
    input logic [DATA_WIDTH - 1:0] rhs, // rs2 value or decoded immediate
    input logic rhs_valid,
    
    input logic [14:12] operation, // funct3
    input logic operation_valid,
    
    input logic [31:25] metadata, // funct7, or imm[11:5] if applicable (otherwise zero)
    input logic metadata_valid,
    
    output logic [DATA_WIDTH -1:0] result,
    output logic arithmetic_code_legal,
    output logic result_valid
);

    always_comb begin
        unique case ({operation, metadata})
            // RV32I operations
            { 3'h0, 7'h00 } : begin result = lhs +  rhs; arithmetic_code_legal = '1; end
            { 3'h0, 7'h20 } : begin result = lhs -  rhs; arithmetic_code_legal = '1; end
            { 3'h4, 7'h00 } : begin result = lhs ^  rhs; arithmetic_code_legal = '1; end
            { 3'h6, 7'h00 } : begin result = lhs |  rhs; arithmetic_code_legal = '1; end
            { 3'h7, 7'h00 } : begin result = lhs &  rhs; arithmetic_code_legal = '1; end
            { 3'h1, 7'h00 } : begin result = lhs << rhs; arithmetic_code_legal = '1; end
            { 3'h5, 7'h00 } : begin result = lhs >> rhs; arithmetic_code_legal = '1; end
            { 3'h5, 7'h20 } : begin result = $signed(lhs) >>> rhs; arithmetic_code_legal = '1; end
            { 3'h2, 7'h00 } : begin result = ($signed(lhs) < $signed(rhs)) ? DATA_WIDTH'(1) : DATA_WIDTH'(0); arithmetic_code_legal = '1; end
            { 3'h3, 7'h00 } : begin result = (lhs < rhs) ? DATA_WIDTH'(1) : DATA_WIDTH'(0); arithmetic_code_legal = '1; end
            
            default : begin result = 'X; arithmetic_code_legal = '0; end
        endcase
    end
    
    assign result_valid = arithmetic_code_legal && rhs_valid && lhs_valid && operation_valid && metadata_valid;
    
endmodule
