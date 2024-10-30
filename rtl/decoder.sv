`timescale 1ns / 1ps

module decoder #(
    localparam INSTRUCTION_WIDTH = 32,
    localparam IMMEDIATE_WIDTH = 32
) (
    input logic [INSTRUCTION_WIDTH - 1:0] instruction_data,
    input logic instruction_data_valid,
    
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
    
    output logic [14:12] funct_3,
    output logic funct_3_valid
);

    logic [6:0] opcode;
    assign opcode = instruction_data[6:0];
    
    assign register_arith  = instruction_data_valid && opcode == 7'b0110011; // R
    assign immediate_arith = instruction_data_valid && opcode == 7'b0010011; // I
    assign load            = instruction_data_valid && opcode == 7'b0000011; // I
    assign store           = instruction_data_valid && opcode == 7'b0100011; // S
    assign branch          = instruction_data_valid && opcode == 7'b1100011; // B
    assign immediate_jump  = instruction_data_valid && opcode == 7'b1101111; // J
    assign register_jump   = instruction_data_valid && opcode == 7'b1100111; // I
    assign load_upper      = instruction_data_valid && opcode == 7'b0110111; // U
    assign load_upper_pc   = instruction_data_valid && opcode == 7'b0010111; // U
    assign environment     = instruction_data_valid && opcode == 7'b1110011; // I
    
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
    
    logic override_immediate_arith; // funct_7 exists, special case for immediate arithmetic
    assign override_immediate_arith = funct_3 == 3'h1 || funct_3 == 3'h5;
    
    assign funct_7[31:25] = (immediate_arith && !override_immediate_arith) ? '0 : instruction_data[31:25];
    assign funct_3[14:12] = instruction_data[14:12];
    
    assign funct_7_valid = r_type || immediate_arith;
    assign funct_3_valid = r_type || i_type || s_type || b_type;
    
    assign register_1 = instruction_data[19:15];
    assign register_2 = instruction_data[24:20];
    assign write_register = instruction_data[11:7];
    
    assign register_1_valid     = r_type || i_type || s_type || b_type;
    assign register_2_valid     = r_type || s_type || b_type;
    assign write_register_valid = r_type || i_type || u_type || j_type;
    
    always_comb begin
        if (!instruction_data_valid) begin
            immediate_data[IMMEDIATE_WIDTH - 1:0] = 'X;
            immediate_valid = 'X;
            opcode_valid = '0;
        end else if (r_type) begin
            immediate_data = 'X;
            immediate_valid = '0;
            opcode_valid = '1;
        end else if (i_type) begin
            immediate_data = (immediate_arith && override_immediate_arith) ?
                $unsigned(instruction_data[24:20]) : // overrided for immediate shifts
                $signed(instruction_data[31:20]); // normal i_type logic
            immediate_valid = '1;
            opcode_valid = '1;
        end else if (s_type) begin
            immediate_data[IMMEDIATE_WIDTH - 1:5] = $signed(instruction_data[31:25]);
            immediate_data[4:0] = instruction_data[11:7];
            immediate_valid = '1;
            opcode_valid = '1;
        end else if (b_type) begin
            immediate_data[IMMEDIATE_WIDTH - 1:12] = $signed(instruction_data[31]);
            immediate_data[10:5] = instruction_data[30:25];
            immediate_data[4:1] = instruction_data[11:8];
            immediate_data[11] = instruction_data[7];
            immediate_data[0] = '0;
            immediate_valid = '1;
            opcode_valid = '1;
        end else if (u_type) begin
            immediate_data[31:12] = instruction_data[31:12];
            immediate_data[11:0] = '0;
            immediate_valid = '1;
            opcode_valid = '1;
        end else if (j_type) begin
            immediate_data[IMMEDIATE_WIDTH - 1:20] = $signed(instruction_data[31]);
            immediate_data[10:1] = instruction_data[30:21];
            immediate_data[11] = instruction_data[20];
            immediate_data[19:12] = instruction_data[19:12];
            immediate_data[0] = '0;
            immediate_valid = '1;
            opcode_valid = '1;
        end else begin
            immediate_data[IMMEDIATE_WIDTH - 1:0] = 'X;
            immediate_valid = 'X;
            opcode_valid = '0;
        end
    end
    
endmodule
