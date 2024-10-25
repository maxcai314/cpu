`timescale 1ns / 1ps

module decode_stage #(
    parameter ADDR_WIDTH = 32,
    localparam INSTRUCTION_WIDTH = 32,
    localparam IMMEDIATE_WIDTH = 32
) (
    input logic clk,
    input logic rst,

    output logic stall_prev, // dictates previous stage
    input logic prev_done, // comes from previous stage

    input logic next_stall, // comes from next stage
    input logic done_next, // dictates next stage

    input logic [ADDR_WIDTH - 1:0] program_count,
    input logic [INSTRUCTION_WIDTH - 1:0] instruction_data,
    input logic instruction_data_valid,
    // todo: exceptions from prev stage

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
    // interal copy of inputs
    logic [ADDR_WIDTH - 1:0] program_count_i;
    logic [INSTRUCTION_WIDTH - 1:0] instruction_data_i;
    logic instruction_data_valid_i;

    decoder decoder (
        // .clk ( clk ),
        // .rst ( rst ),
        
        .instruction_data ( instruction_data_i ),
        .instruction_data_valid ( instruction_data_valid_i ),
        
        .register_arith ( register_arith ),
        .immediate_arith ( immediate_arith ),
        .load ( load ),
        .store ( store ),
        .branch ( branch ),
        .immediate_jump ( immediate_jump ),
        .register_jump ( register_jump ),
        .load_upper ( load_upper ),
        .load_upper_pc ( load_upper_pc ),
        .environment ( environment ),
        .opcode_valid ( opcode_valid ),
        
        .immediate_data ( immediate_data ),
        .immediate_valid ( immediate_valid ),
        
        .register_1 ( register_1 ),
        .register_1_valid ( register_1_valid ),
        
        .register_2 ( register_2 ),
        .register_2_valid ( register_2_valid ),
        
        .write_register ( write_register ),
        .write_register_valid ( write_register_valid ),
        
        .funct_7 ( funct_7 ),
        .funct_7_valid ( funct_7_valid ),
        
        .funct_3 ( funct_3 ),
        .funct_3_valid ( funct_3_valid )
    );

    logic transfer_prev;
    logic transfer_next;
    logic has_input;

    always_comb begin
        transfer_prev = prev_done && !stall_prev;
        transfer_next = done_next && !next_stall;

        stall_prev = has_input && !transfer_next;

        done_next = has_input; // combinational only; no delay
    end

    always_ff @(posedge clk) if (rst) begin
        has_input <= '0;
    end

    always_ff @(posedge clk) if (!rst) begin
        if (!has_input || transfer_next) begin
            // try to accept new input
            if (transfer_prev) begin
                program_count_i <= program_count;
                instruction_data_i <= instruction_data;
                instruction_data_valid_i <= instruction_data_valid;
                has_input <= '1;
            end else begin
                has_input <= '0;
            end
        end
    end

endmodule