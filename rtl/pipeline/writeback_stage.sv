`timescale 1ns / 1ps

// loads or stores
module writeback_stage #(
    localparam ADDR_WIDTH = 32,
    localparam DATA_WIDTH = 32,
    localparam INSTRUCTION_WIDTH = 32,
    localparam IMMEDIATE_WIDTH = 32,
    localparam NUM_REGISTERS = 32,
    localparam REGISTER_INDEXING_WIDTH = $clog2(NUM_REGISTERS),
) (
    input logic clk,
    input logic rst,

    output logic stall_prev, // dictates previous stage
    input logic prev_done, // comes from previous stage

    input logic next_stall, // comes from next stage
    input logic done_next, // dictates next stage

    // global interactions
    output logic [REGISTER_INDEXING_WIDTH - 1:0] write_register,
    output logic [DATA_WIDTH - 1:0] write_data,
    output logic write_activate, // assert that write reg and data are valid when using this
    // todo: exceptions

    // pipeline inputs
    input logic [ADDR_WIDTH - 1:0] program_count_in,
    input logic program_count_valid_in,

    input logic register_arith_in,
    input logic immediate_arith_in,
    input logic load_in,
    input logic store_in,
    input logic branch_in,
    input logic immediate_jump_in,
    input logic register_jump_in,
    input logic load_upper_in,
    input logic load_upper_pc_in,
    input logic environment_in,
    input logic opcode_legal_in,

    input logic [REGISTER_INDEXING_WIDTH - 1:0] write_register_in,
    input logic write_register_valid_in,

    input logic [DATA_WIDTH - 1:0] result_data_in, // register result or effective address
    input logic result_data_valid_in,
    // todo: exceptions from prev stage

    // pipeline outputs
    output logic [ADDR_WIDTH - 1:0] program_count_out,
    output logic program_count_valid_out,
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
    logic [REGISTER_INDEXING_WIDTH - 1:0] write_register_i;
    logic write_register_valid_i;
    logic [DATA_WIDTH - 1:0] result_data_i;
    logic result_data_valid_i;

    // pass-through
    always_comb begin
        program_count_out = program_count_i;
        program_count_valid_out = program_count_valid_i;
    end

    assign write_activate = register_arith_i || immediate_arith_i || load_i
                                || immediate_jump_i || register_jump_i
                                || load_upper_i || load_upper_pc_i || opcode_legal_i;
    
    assign write_register = write_register_i;
    assign write_data = result_data_i; // assert that all this is valid when write_activate

    // transfer logic
    logic transfer_prev;
    logic transfer_next;
    logic has_input;

    always_comb begin
        transfer_prev = prev_done && !stall_prev;
        transfer_next = done_next && !next_stall;

        stall_prev = rst || (has_input && !transfer_next);
        done_next = !rst && has_input; // register writing doesn't stall
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
                write_register_i <= write_register_in;
                write_register_valid_i <= write_register_valid_in;
                result_data_i <= result_data_in;
                result_data_valid_i <= result_data_valid_in;

                has_input <= '1;
            end else begin
                has_input <= '0;
            end
        end
    end

endmodule