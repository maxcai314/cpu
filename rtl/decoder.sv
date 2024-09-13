`timescale 1ns / 1ps

module decoder #(
    localparam INSTRUCTION_WIDTH = 32,
    localparam IMMEDIATE_WIDTH = 32
) (
    input logic clk,
    input logic rst,
    
    input logic [INSTRUCTION_WIDTH - 1:0] instruction_data,
    
    output logic register_arith,
    output logic immediate_arith,
    output logic load,
    output logic store,
    output logic branch,
    output logic immediate_jump,
    output logic register_jump,
    output logic load_upper,
    output logic load_upper_pc,
    output logic environment,
    output logic opcode_valid,
    
    output logic [IMMEDIATE_WIDTH - 1:0] immediate_data,
    output logic immediate_valid,
    
    output logic [19:15] register_1,
    output logic register_1_valid,
    
    output logic [24:20] register_2,
    output logic register_2_valid,
    
    output logic [11:7] write_register,
    output logic write_register_valid,
    
    output logic [31:25] funct_7,
    output logic funct_7_valid,
    
    output logic [14:2] funct_3,
    output logic funct_3_valid
);

    logic [6:0] opcode;
    assign opcode = instruction_data[6:0];
    
    assign register_arith  = opcode == 7'b0110011; // R
    assign immediate_arith = opcode == 7'b0010011; // I
    assign load            = opcode == 7'b0000011; // I
    assign store           = opcode == 7'b0100011; // S
    assign branch          = opcode == 7'b1100011; // B
    assign immediate_jump  = opcode == 7'b1101111; // J
    assign register_jump   = opcode == 7'b1100111; // I
    assign load_upper      = opcode == 7'b0110111; // U
    assign load_upper_pc   = opcode == 7'b0010111; // U
    assign environment     = opcode == 7'b1110011; // I
    
    logic r_type;
    logic i_type;
    logic s_type;
    logic b_type;
    logic u_type;
    logic j_type;
    
    assign r_type = register_arith;
    assign i_type = immediate_arith || load || register_jump || environment;
    assign s_type = store;
    assign b_type = branch;
    assign u_type = load_upper || load_upper_pc;
    assign j_type = immediate_jump;
    
    assign funct_7_valid = r_type;
    assign funct_e_valid = r_type || i_type || s_type || b_type;
    
    assign register_1 = instruction_data[19:15];
    assign register_2 = instruction_data[24:20];
    assign write_register = instruction_data[11:7];
    
    assign register_1_valid = r_type || i_type || s_type || b_type;
    assign register_2_valid = r_type || s_type || b_type;
    assign write_register_valid = r_type || i_type || u_type || j_type;
    
    always_comb begin
        if (r_type) begin
            immediate_data = 'X;
            immediate_valid = '0;
            opcode_valid = '1;
        end else if (i_type) begin
            immediate_data[11:0] = instruction_data[31:20];
            immediate_data[IMMEDIATE_WIDTH - 1:12] = '0;
            immediate_valid = '1;
            opcode_valid = '1;
        end else if (s_type) begin
            immediate_data[11:5] = instruction_data[31:25];
            immediate_data[4:0] = instruction_data[11:7];
            immediate_data[IMMEDIATE_WIDTH - 1:12] = '0;
            immediate_valid = '1;
            opcode_valid = '1;
        end else if (b_type) begin
            immediate_data[12] = instruction_data[31];
            immediate_data[10:5] = instruction_data[30:25];
            immediate_data[4:1] = instruction_data[11:8];
            immediate_data[11] = instruction_data[7];
            immediate_data[0] = '0;
            immediate_data[IMMEDIATE_WIDTH - 1:13] = '0;
            immediate_valid = '1;
            opcode_valid = '1;
        end else if (u_type) begin
            immediate_data[31:12] = instruction_data[31:12];
            immediate_data[11:0] = '0;
            immediate_valid = '1;
            opcode_valid = '1;
        end else if (j_type) begin
            immediate_data[20] = instruction_data[31];
            immediate_data[10:1] = instruction_data[30:21];
            immediate_data[11] = instruction_data[20];
            immediate_data[19:12] = instruction_data[19:12];
            immediate_data[0] = '0;
            immediate_data[IMMEDIATE_WIDTH - 1:21] = '0;
            immediate_valid = '1;
            opcode_valid = '1;
        end else begin
            immediate_data[IMMEDIATE_WIDTH - 1:0] = 'X;
            immediate_valid = 'X;
            opcode_valid = '0;
        end
    end
    
endmodule
