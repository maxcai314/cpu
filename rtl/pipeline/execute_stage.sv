`timescale 1ns / 1ps

// uses ALU to compute result or effective address
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
    output logic done_next, // dictates next stage

    // global interactions
    // ...

    // pipeline inputs
    input logic [ADDR_WIDTH - 1:0] program_count_in,
    input logic program_count_valid_in,

    input logic register_arith_in,  // register arithmetic
    input logic immediate_arith_in, // immediate arithmetic
    input logic load_in,            // register_1_data + immediate
    input logic store_in,           // register_1_data + immediate
    input logic branch_in,          // no result
    input logic immediate_jump_in,  // program_count + 4
    input logic register_jump_in,   // program_count + 4
    input logic load_upper_in,      // upper_immediate + 0
    input logic load_upper_pc_in,   // upper_immediate + program_count
    input logic environment_in,     // no result
    input logic opcode_legal_in,
    
    input logic [IMMEDIATE_WIDTH - 1:0] immediate_data_in,
    input logic immediate_data_valid_in,
    
    input logic [DATA_WIDTH - 1:0] register_1_data_in,
    input logic register_1_data_valid_in,
    
    input logic [DATA_WIDTH - 1:0] register_2_data_in,
    input logic register_2_data_valid_in,
    
    input logic [REGISTER_INDEXING_WIDTH - 1:0] write_register_in,
    input logic write_register_valid_in,
    
    input logic [31:25] funct_7_in,
    input logic funct_7_valid_in,
    
    input logic [14:12] funct_3_in,
    input logic funct_3_valid_in,
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

    output logic [31:25] funct_7_out,
    output logic funct_7_valid_out,
    
    output logic [14:12] funct_3_out,
    output logic funct_3_valid_out,
    
    output logic [DATA_WIDTH - 1:0] memory_store_data_out, // register 2
    output logic memory_store_data_valid_out,

    output logic [REGISTER_INDEXING_WIDTH - 1:0] write_register_out,
    output logic write_register_valid_out,

    output logic [DATA_WIDTH - 1:0] result_data_out, // register result or effective address
    output logic result_data_valid_out
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

    // pass-through
    always_comb begin
        program_count_out = program_count_i;
        program_count_valid_out = program_count_valid_i;
        register_arith_out = register_arith_i;
        immediate_arith_out = immediate_arith_i;
        load_out = load_i;
        store_out = store_i;
        branch_out = branch_i;
        immediate_jump_out = immediate_jump_i;
        register_jump_out = register_jump_i;
        load_upper_out = load_upper_i;
        load_upper_pc_out = load_upper_pc_i;
        environment_out = environment_i;
        opcode_legal_out = opcode_legal_i;
        funct_7_out = funct_7_i;
        funct_7_valid_out = funct_7_valid_i;
        funct_3_out = funct_3_i;
        funct_3_valid_out = funct_3_valid_i;
        write_register_out = write_register_i;
        write_register_valid_out = write_register_valid_i;
        memory_store_data_out = register_2_data_i;
        memory_store_data_valid_out = register_2_data_valid_i && store_i;
    end

    logic [IMMEDIATE_WIDTH - 1:0] upper_immediate;
    assign upper_immediate = immediate_data_i << 12;

    logic [DATA_WIDTH - 1:0] lhs;
    logic lhs_valid;

    logic [DATA_WIDTH - 1:0] rhs;
    logic rhs_valid;

    logic [14:12] operation; // funct3
    logic operation_valid;
    
    logic [31:25] metadata; // funct7, or imm[11:5] if applicable (otherwise zero)
    logic metadata_valid;
    
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

        .result ( result_data_out ),
        .arithmetic_code_legal ( arithmetic_code_legal ), // should result in an exception
        .result_valid ( result_data_valid_out )
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
        done_next = !rst && has_input; // single-cycle (until we implement multiplication and division)
        transfer_next = done_next && !next_stall;

        stall_prev = rst || (has_input && !transfer_next);
        transfer_prev = prev_done && !stall_prev;
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
                register_arith_i <= register_arith_in;
                immediate_arith_i <= immediate_arith_in;
                load_i <= load_in;
                store_i <= store_in;
                branch_i <= branch_in;
                immediate_jump_i <= immediate_jump_in;
                register_jump_i <= register_jump_in;
                load_upper_i <= load_upper_in;
                load_upper_pc_i <= load_upper_pc_in;
                environment_i <= environment_in;
                opcode_legal_i <= opcode_legal_in;
                immediate_data_i <= immediate_data_in;
                immediate_data_valid_i <= immediate_data_valid_in;
                register_1_data_i <= register_1_data_in;
                register_1_data_valid_i <= register_1_data_valid_in;
                register_2_data_i <= register_2_data_in;
                register_2_data_valid_i <= register_2_data_valid_in;
                write_register_i <= write_register_in;
                write_register_valid_i <= write_register_valid_in;
                funct_7_i <= funct_7_in;
                funct_7_valid_i <= funct_7_valid_in;
                funct_3_i <= funct_3_in;
                funct_3_valid_i <= funct_3_valid_in;

                has_input <= '1;
            end else begin
                has_input <= '0;
            end
        end
    end

endmodule