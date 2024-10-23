`timescale 1ns / 1ps

module count #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input logic clk,
    input logic rst,
    
    input logic execution_done,
    
    input logic [DATA_WIDTH - 1:0] lhs,
    input logic lhs_valid,
    
    input logic [DATA_WIDTH - 1:0] rhs,
    input logic rhs_valid,
    
    input logic [14:12] operation, // funct_3
    input logic operation_valid,
    
    input logic [ADDR_WIDTH - 1:0] immediate_offset,
    input logic immediate_offset_valid,
    
    input logic [ADDR_WIDTH - 1:0] register_address,
    input logic register_address_valid,
    
    input logic branch,
    input logic immediate_jump,
    input logic register_jump,
    
    output logic [ADDR_WIDTH - 1:0] program_count,
    output logic [ADDR_WIDTH - 1:0] next_instruction
);
    
    logic branch_condition;
    logic branch_valid;
    
    logic branch_condition_valid;
    assign branch_condition_valid = branch_valid && operation_valid && lhs_valid && rhs_valid;
    
    logic halted;
    
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
    end
    
    always_ff @(posedge clk) if (!rst && !halted) begin
        if (branch && branch_condition)
            program_count <= program_count + immediate_offset;
        else if (immediate_jump)
            program_count <= program_count + immediate_offset;
        else if (register_jump)
            program_count <= register_address + immediate_offset;
        else
            program_count <= next_instruction;
    end
    
    logic state_valid;
    always_comb begin
        if (branch)
            state_valid = branch_condition_valid && immediate_offset_valid;
        else if (immediate_jump) begin
            state_valid = immediate_offset_valid;
        end else if (register_jump)
            state_valid = register_address_valid && immediate_offset_valid && operation == 3'h0; // for some reason the spec requires it
        else
            state_valid = '1;
    end
    
    assign halted = !execution_done || !state_valid;
    
endmodule
