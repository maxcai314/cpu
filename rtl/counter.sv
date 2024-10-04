`timescale 1ns / 1ps

module counter #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input logic clk,
    input logic rst,
    
    input logic [DATA_WIDTH - 1:0] lhs,
    input logic [DATA_WIDTH - 1:0] rhs,
    input logic [14:12] operation, // funct_3
    
    input logic [ADDR_WIDTH - 1:0] immediate_offset,
    input logic [ADDR_WIDTH - 1:0] register_address,
    
    input logic branch,
    input logic immediate_jump,
    input logic register_jump,
    
    output logic [ADDR_WIDTH - 1:0] program_count,
    output logic [ADDR_WIDTH - 1:0] next_instruction,
    output logic operation_valid
);
    
    logic branch_condition;
    logic branch_valid;
    logic ready;
    
    always_comb begin
        unique case (operation)
            3'h0 : begin branch_condition = lhs == rhs;                       branch_valid = '1; end
            3'h1 : begin branch_condition = lhs != rhs;                       branch_valid = '1; end
            3'h4 : begin branch_condition = $signed(lhs) <  $signed(rhs);     branch_valid = '1; end
            3'h5 : begin branch_condition = $signed(lhs) >= $signed(rhs);     branch_valid = '1; end
            3'h6 : begin branch_condition = $unsigned(lhs) <  $unsigned(rhs); branch_valid = '1; end
            3'h7 : begin branch_condition = $unsigned(lhs) >= $unsigned(rhs); branch_valid = '1; end
            
            default : begin branch_condition = 'X; branch_valid = '0; end
        endcase
    end
    
    assign next_instruction = program_count + 4;
    
    always_ff @(posedge clk) if (rst) begin
        program_count <= 32'h0000_0000;
        ready <= '0;
    end
    
    always_ff @(posedge clk) if (!rst && !ready) begin
        ready <= '1; // skip a cycle
    end
    
    always_ff @(posedge clk) if (!rst && ready) begin
        if (branch && branch_condition)
            program_count <= next_instruction + immediate_offset;
        else if (immediate_jump)
            program_count <= next_instruction + immediate_offset;
        else if (register_jump)
            program_count <= register_address + immediate_offset;
        else
            program_count <= next_instruction;
    end
    
    always_comb begin
        if (branch)
            operation_valid = branch_valid;
        else if (register_jump)
            operation_valid = operation == 3'h0; // for some reason the spec requires it
        else
            operation_valid = '1;
    end
    
endmodule
