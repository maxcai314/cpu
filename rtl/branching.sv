`timescale 1ns / 1ps

module branching #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input logic [DATA_WIDTH - 1:0] lhs,
    input logic lhs_valid,
    
    input logic [DATA_WIDTH - 1:0] rhs,
    input logic rhs_valid,

    input logic [14:12] operation, // funct_3
    input logic operation_valid,

    output logic branch_condition,
    output logic branch_code_valid,
    output logic branch_valid
);
    
    always_comb begin
        unique case (operation)
            3'h0 : begin branch_condition = lhs == rhs;                       branch_code_valid = '1; end
            3'h1 : begin branch_condition = lhs != rhs;                       branch_code_valid = '1; end
            3'h4 : begin branch_condition = $signed(lhs) <  $signed(rhs);     branch_code_valid = '1; end
            3'h5 : begin branch_condition = $signed(lhs) >= $signed(rhs);     branch_code_valid = '1; end
            3'h6 : begin branch_condition = $unsigned(lhs) <  $unsigned(rhs); branch_code_valid = '1; end
            3'h7 : begin branch_condition = $unsigned(lhs) >= $unsigned(rhs); branch_code_valid = '1; end
            
            default : begin branch_condition = 'X; branch_code_valid = '0; end
        endcase
    end

    assign branch_valid = branch_code_valid && lhs_valid && rhs_valid && operation_valid;

endmodule