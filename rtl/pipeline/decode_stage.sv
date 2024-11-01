`timescale 1ns / 1ps

// decodes and fetches register data
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
    output logic done_next, // dictates next stage

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
    input logic [ADDR_WIDTH - 1:0] program_count_in,
    input logic program_count_valid_in,
    input logic [INSTRUCTION_WIDTH - 1:0] instruction_data_in,
    input logic instruction_data_valid_in,
    // todo: exceptions from prev stage

    // pipeline outputs
    output logic [ADDR_WIDTH - 1:0] program_count_out,
    output logic program_count_valid_out,

    output logic register_arith_out,
    output logic immediate_arith_out,
    output logic load_out,
    output logic store_out,
    output logic branch_out,
    output logic immediate_jump_out,
    output logic register_jump_out,
    output logic load_upper_out,
    output logic load_upper_pc_out,
    output logic environment_out,
    output logic opcode_legal_out,
    
    output logic [IMMEDIATE_WIDTH - 1:0] immediate_data_out,
    output logic immediate_data_valid_out,
    
    output logic [DATA_WIDTH - 1:0] register_1_data_out,
    output logic register_1_data_valid_out,
    
    output logic [DATA_WIDTH - 1:0] register_2_data_out,
    output logic register_2_data_valid_out,
    
    output logic [REGISTER_INDEXING_WIDTH - 1:0] write_register_out,
    output logic write_register_valid_out,
    
    output logic [31:25] funct_7_out,
    output logic funct_7_valid_out,
    
    output logic [14:12] funct_3_out,
    output logic funct_3_valid_out
);
    // interal copy of inputs
    logic [ADDR_WIDTH - 1:0] program_count_i;
    logic program_count_valid_i;
    logic [INSTRUCTION_WIDTH - 1:0] instruction_data_i;
    logic instruction_data_valid_i;

    logic immediate_valid;
    logic register_1_valid;
    logic register_2_valid;

    decoder decoder (
        // .clk ( clk ),
        // .rst ( rst ),
        
        .instruction_data ( instruction_data_i ),
        .instruction_data_valid ( instruction_data_valid_i ),
        
        .register_arith ( register_arith_out ),
        .immediate_arith ( immediate_arith_out ),
        .load ( load_out ),
        .store ( store_out ),
        .branch ( branch_out ),
        .immediate_jump ( immediate_jump_out ),
        .register_jump ( register_jump_out ),
        .load_upper ( load_upper_out ),
        .load_upper_pc ( load_upper_pc_out ),
        .environment ( environment_out ),
        .opcode_legal ( opcode_legal_out ), // should result in exception
        
        .immediate_data ( immediate_data_out ),
        .immediate_valid ( immediate_valid ),
        
        .register_1 ( register_read_1 ),
        .register_1_valid ( register_1_valid ),
        
        .register_2 ( register_read_2 ),
        .register_2_valid ( register_2_valid ),
        
        .write_register ( write_register_out ),
        .write_register_valid ( write_register_valid_out ),
        
        .funct_7 ( funct_7_out ),
        .funct_7_valid ( funct_7_valid_out ),
        
        .funct_3 ( funct_3_out ),
        .funct_3_valid ( funct_3_valid_out )
    );

    assign immediate_data_valid_out = instruction_data_valid_i && immediate_valid;

    assign program_count_out = program_count_i;
    assign program_count_valid_out = program_count_valid_i;

    logic register_1_stall;
    logic register_2_stall;
    
    always_comb begin
        register_1_data_out = register_read_1_data;
        register_1_data_valid_out = register_1_valid && !register_read_1_contended;
        register_1_stall = register_1_valid && register_read_1_contended;

        register_2_data_out = register_read_2_data;
        register_2_data_valid_out = register_2_valid && !register_read_2_contended;
        register_2_stall = register_2_valid && register_read_2_contended;
    end

    logic branch_condition;
    logic branch_code_legal;
    logic branch_valid;

    branching branching (
        .lhs( register_1_data_out ),
        .lhs_valid( register_1_data_valid_out ),

        .rhs( register_2_data ),
        .rhs_valid( register_2_data_valid ),

        .operation( funct_3 ),
        .operation_valid( funct_3_valid ),

        .branch_condition( branch_condition ),
        .branch_code_legal( branch_code_legal ), // should result in exception
        .branch_valid( branch_valid )
    );

    always_comb begin
        if (branch_out) begin
            control_flow_affected = branch_condition;
            jump_target = program_count_i + immediate_data_out;
            jump_target_valid = program_count_valid_i && branch_valid && immediate_data_valid_out;
        end else if (immediate_jump_out) begin
            control_flow_affected = '1;
            jump_target = program_count_i + immediate_data_out;
            jump_target_valid = program_count_valid_i && immediate_data_valid_out;
        end else if (register_jump_out) begin
            control_flow_affected = '1;
            jump_target = register_1_data + immediate_data_out;
            jump_target_valid = register_1_data_valid && immediate_data_valid_out;
        end else begin
            control_flow_affected = '0;
            jump_target = 'X;
            jump_target_valid = '0;
        end
    end

    // transfer logic
    logic transfer_prev;
    logic transfer_next;
    logic has_input;

    always_comb begin
        transfer_prev = prev_done && !stall_prev;
        transfer_next = done_next && !next_stall;

        stall_prev = rst || (has_input && !transfer_next);

        done_next = !rst && has_input && !register_1_stall && !register_2_stall;
    end

    always_ff @(posedge clk) if (rst) begin
        has_input <= '0;
    end

    always_ff @(posedge clk) if (!rst) begin
        if (!has_input || transfer_next) begin
            // try to accept new input
            if (transfer_prev) begin
                program_count_i <= program_count_in;
                program_count_valid_i <= program_count_valid_in;
                instruction_data_i <= instruction_data_in;
                instruction_data_valid_i <= instruction_data_valid_in;
                
                has_input <= '1;
            end else begin
                has_input <= '0;
            end
        end
    end

endmodule