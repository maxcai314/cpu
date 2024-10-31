`timescale 1ns / 1ps

module execute_stage #(
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

    // global interactions
    // ...

    // pipeline inputs
    input logic [ADDR_WIDTH - 1:0] program_count,
    input logic program_count_valid,

    input logic register_arith,  // register arithmetic
    input logic immediate_arith, // immediate arithmetic
    input logic load,            // register_1_data + immediate
    input logic store,           // register_1_data + immediate
    input logic branch,          // no result
    input logic immediate_jump,  // program_count + 4
    input logic register_jump,   // program_count + 4
    input logic load_upper,      // upper_immediate + 0
    input logic load_upper_pc,   // upper_immediate + program_count
    input logic environment,     // no result
    input logic opcode_legal,
    
    input logic [IMMEDIATE_WIDTH - 1:0] immediate_data,
    input logic immediate_data_valid,
    
    input logic [DATA_WIDTH - 1:0] register_1_data,
    input logic register_1_data_valid,
    
    input logic [DATA_WIDTH - 1:0] register_2_data,
    input logic register_2_data_valid,
    
    input logic [REGISTER_INDEXING_WIDTH - 1:0] write_register,
    input logic write_register_valid,
    
    input logic [31:25] funct_7,
    input logic funct_7_valid,
    
    input logic [14:12] funct_3,
    input logic funct_3_valid
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
    output logic opcode_legal,

    output logic [31:25] funct_7,
    output logic funct_7_valid,
    
    output logic [14:12] funct_3,
    output logic funct_3_valid

    output logic [DATA_WIDTH - 1:0] register_1_data,
    output logic register_1_data_valid,
    
    output logic [DATA_WIDTH - 1:0] register_2_data,
    output logic register_2_data_valid,

    output logic [REGISTER_INDEXING_WIDTH - 1:0] write_register,
    output logic write_register_valid,

    output logic [DATA_WIDTH - 1:0] result_data, // register result or effective address
    output logic result_data_valid,
);

    // internal copy of inputs
    logic [ADDR_WIDTH - 1:0] program_count_i;
    logic program_count_valid_i;
    logic register_arith_i;
    logic immediate_arith_i;
    logic load_i;
    logic store_i;
    logic branch_i;
    logic immediate_jump_i;
    logic register_jump_i;
    logic load_upper_i;
    logic load_upper_pc_i;
    logic environment_i;
    logic opcode_legal_i;
    logic [IMMEDIATE_WIDTH - 1:0] immediate_data_i;
    logic immediate_data_valid_i;
    logic [DATA_WIDTH - 1:0] register_1_data_i;
    logic register_1_data_valid_i;
    logic [DATA_WIDTH - 1:0] register_2_data_i;
    logic register_2_data_valid_i;
    logic [REGISTER_INDEXING_WIDTH - 1:0] write_register_i;
    logic write_register_valid_i;
    logic [31:25] funct_7_i;
    logic funct_7_valid_i;
    logic [14:12] funct_3_i;
    logic funct_3_valid_i;

    logic upper_immediate [IMMEDIATE_WIDTH - 1:0];
    assign upper_immediate = immediate_data << 12;

    logic [DATA_WIDTH - 1:0] lhs;
    logic lhs_valid;

    logic [DATA_WIDTH - 1:0] rhs;
    logic rhs_valid;

    logic [14:12] operation, // funct3
    logic operation_valid,
    
    logic [31:25] metadata, // funct7, or imm[11:5] if applicable (otherwise zero)
    logic metadata_valid,
    
    logic arithmetic_code_legal;

    arithmetic arithmetic (
        .lhs ( lhs ),
        .lhs_valid ( lhs_valid ),

        .rhs ( rhs ),
        .rhs_valid ( rhs_valid ),

        .operation ( operation ),
        .operation_valid ( operation_valid ),

        .metadata ( metadata ),
        .metadata_valid ( metadata_valid ),

        .result ( result_data ),
        .arithmetic_code_legal ( arithmetic_code_legal ), // should result in an exception
        .result_valid ( result_data_valid )
    );

    always_comb begin
        if (register_arith_i) begin
            lhs = register_1_data_i;
            lhs_valid = register_1_data_valid_i;

            rhs = register_2_data_i;
            rhs_valid = register_2_data_valid_i;

            operation = funct_3_i;
            operation_valid = funct_3_valid_i;

            metadata = funct_7_i;
            metadata_valid = funct_7_valid_i;
        end else if (immediate_arith_i) begin
            lhs = register_1_data_i;
            lhs_valid = register_1_data_valid_i;

            rhs = immediate_data_i;
            rhs_valid = immediate_data_valid_i;

            operation = funct_3_i;
            operation_valid = funct_3_valid_i;

            metadata = funct_7_i;
            metadata_valid = funct_7_valid_i;
        end else if (load_i || store_i) begin
            lhs = register_1_data_i;
            lhs_valid = register_1_data_valid_i;

            rhs = immediate_data_i;
            rhs_valid = immediate_data_valid_i;

            operation = 3'h0; // addition
            operation_valid = '1;

            metadata = 7'h00;
            metadata_valid = '1;
        end else if (immediate_jump_i || register_jump_i) begin
            lhs = program_count_i;
            lhs_valid = program_count_valid_i;

            rhs = 32'h0000_0004;
            rhs_valid = '1;

            operation = 3'h0; // addition
            operation_valid = '1;

            metadata = 7'h00;
            metadata_valid = '1;
        end else if (load_upper_i) begin
            lhs = upper_immediate;
            lhs_valid = immediate_data_valid_i;

            rhs = 32'h0000_0000;
            rhs_valid = '1;

            operation = 3'h0; // addition
            operation_valid = '1;

            metadata = 7'h00;
            metadata_valid = '1;
        end else if (load_upper_pc_i) begin
            lhs = upper_immediate;
            lhs_valid = immediate_data_valid_i;

            rhs = program_count_i;
            rhs_valid = program_count_valid_i;

            operation = 3'h0; // addition
            operation_valid = '1;

            metadata = 7'h00;
            metadata_valid = '1;
        end else begin
            lhs = 'X;
            lhs_valid = '0;

            rhs = 'X;
            rhs_valid = '0;

            operation = 'X;
            operation_valid = '0;

            metadata = 'X;
            metadata_valid = '0;
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

        done_next = !rst && has_input; // single-cycle (until we implement multiplication and division)
    end

    always_ff @(posedge clk) if (rst) begin
        has_input <= '0;
    end

    always_ff @(posedge clk) if (!rst) begin
        if (!has_input || transfer_next) begin
            // try to accept new input
            if (transfer_prev) begin
                program_count_i <= program_count;
                program_count_valid_i <= program_count_valid;
                register_arith_i <= register_arith;
                immediate_arith_i <= immediate_arith;
                load_i <= load;
                store_i <= store;
                branch_i <= branch;
                immediate_jump_i <= immediate_jump;
                register_jump_i <= register_jump;
                load_upper_i <= load_upper;
                load_upper_pc_i <= load_upper_pc;
                environment_i <= environment;
                opcode_legal_i <= opcode_legal;
                immediate_data_i <= immediate_data;
                immediate_data_valid_i <= immediate_data_valid;
                register_1_data_i <= register_1_data;
                register_1_data_valid_i <= register_1_data_valid;
                register_2_data_i <= register_2_data;
                register_2_data_valid_i <= register_2_data_valid;
                write_register_i <= write_register;
                write_register_valid_i <= write_register_valid;
                funct_7_i <= funct_7;
                funct_7_valid_i <= funct_7_valid;
                funct_3_i <= funct_3;
                funct_3_valid_i <= funct_3_valid;

                has_input <= '1;
            end else begin
                has_input <= '0;
            end
        end
    end

endmodule