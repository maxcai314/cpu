`timescale 1ns / 1ps

module decode_stage #(
    localparam ADDR_WIDTH = 32,
    localparam DATA_WIDTH = 32,
    localparam INSTRUCTION_WIDTH = 32,
    localparam IMMEDIATE_WIDTH = 32,
    localparam NUM_REGISTERS = 32,
    localparam REGISTER_INDEXING_WIDTH = $clog2(NUM_REGISTERS)
) (
    input logic clk,
    input logic rst,

    output logic stall_prev, // dictates previous stage
    input logic prev_done, // comes from previous stage

    input logic next_stall, // comes from next stage
    input logic done_next, // dictates next stage

    // register interactions
    output logic [REGISTER_INDEXING_WIDTH - 1:0] register_read_1,
    input logic [DATA_WIDTH - 1:0] register_read_1_data,
    input logic register_read_1_contended,

    output logic [REGISTER_INDEXING_WIDTH - 1:0] register_read_2,
    input logic [DATA_WIDTH - 1:0] register_read_2_data,
    input logic register_read_2_contended,

    // global interactions
    output logic control_flow_affected,
    output logic [ADDR_WIDTH - 1:0] jump_target,
    output logic jump_target_valid,

    // pipeline inputs
    input logic [ADDR_WIDTH - 1:0] program_count,
    input logic [INSTRUCTION_WIDTH - 1:0] instruction_data,
    input logic instruction_data_valid,
    // todo: exceptions from prev stage

    // pipeline outputs
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
    
    output logic [DATA_WIDTH - 1:0] register_1_data,
    output logic register_1_data_valid,
    
    output logic [DATA_WIDTH - 1:0] register_2_data,
    output logic register_2_data_valid,
    
    output logic [REGISTER_INDEXING_WIDTH - 1:0] write_register,
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

    logic register_1_valid;
    logic register_2_valid;

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
        
        .register_1 ( register_read_1 ),
        .register_1_valid ( register_1_valid ),
        
        .register_2 ( register_read_2 ),
        .register_2_valid ( register_2_valid ),
        
        .write_register ( write_register ),
        .write_register_valid ( write_register_valid ),
        
        .funct_7 ( funct_7 ),
        .funct_7_valid ( funct_7_valid ),
        
        .funct_3 ( funct_3 ),
        .funct_3_valid ( funct_3_valid )
    );

    branching branching (
        .lhs( register_1_data ),
        .lhs_valid( register_1_data_valid ),

        .rhs( register_2_data ),
        .rhs_valid( register_2_data_valid ),

        .operation( funct_3 ),
        .operation_valid( funct_3_valid ),

        .branch_condition( control_flow_affected ),
        .branch_valid( jump_target_valid )
    );

    logic register_1_stall;
    logic register_2_stall;
    
    always_comb begin
        register_1_data = register_read_1_data;
        register_1_data_valid = register_1_valid && !register_read_1_contended;
        register_1_stall = register_1_valid && register_read_1_contended;

        register_2_data = register_read_2_data;
        register_2_data_valid = register_2_valid && !register_read_2_contended;
        register_2_stall = register_2_valid && register_read_2_contended;
    end

    logic transfer_prev;
    logic transfer_next;
    logic has_input;

    always_comb begin
        transfer_prev = prev_done && !stall_prev;
        transfer_next = done_next && !next_stall;

        stall_prev = has_input && !transfer_next;

        done_next = has_input && !register_1_stall && !register_2_stall;
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