`timescale 1ns / 1ps

// decodes and fetches register data
module fetch_stage #(
    localparam ADDR_WIDTH = 32,
    localparam INSTRUCTION_WIDTH = 32,
    localparam DATA_WIDTH = 32
) (
    input logic clk,
    input logic rst,

    output logic stall_prev, // dictates previous stage
    input logic prev_done, // comes from previous stage

    input logic next_stall, // comes from next stage
    output logic done_next, // dictates next stage

    // global interactions
    input logic flush_pipeline, // flush the pipeline

    // memory interactions
    output logic [ADDR_WIDTH - 1:0] instruction_addr,
    output logic instruction_fetch_activate, // assert that fetch addr is valid when using this
    input logic [DATA_WIDTH - 1:0] instruction_data,
    input logic instruction_fetch_done,

    // pipeline inputs
    input logic [ADDR_WIDTH - 1:0] program_count_in,
    input logic program_count_valid_in,
    // todo: exceptions from prev stage

    // pipeline outputs
    output logic [ADDR_WIDTH - 1:0] program_count_out,
    output logic program_count_valid_out,
    output logic [INSTRUCTION_WIDTH - 1:0] instruction_data_out,
    output logic instruction_data_valid_out
);
    // interal copy of inputs
    logic [ADDR_WIDTH - 1:0] program_count_i;
    logic program_count_valid_i;
    
    assign program_count_out = program_count_i;
    assign program_count_valid_out = program_count_valid_i;

    // transfer logic
    logic transfer_prev;
    logic transfer_next;
    logic has_input;

    always_comb begin
        instruction_addr = program_count_i;
        instruction_fetch_activate = has_input;
        instruction_data_out = instruction_data;
        instruction_data_valid_out = instruction_fetch_done;
    end

    always_comb begin
        if (flush_pipeline) begin
            done_next = '0;
            transfer_next = done_next && !next_stall;

            stall_prev = '0;
            transfer_prev = prev_done && !stall_prev;
        end else begin
            done_next = !rst && has_input && instruction_fetch_done;
            transfer_next = done_next && !next_stall;

            stall_prev = rst || (has_input && !transfer_next);
            transfer_prev = prev_done && !stall_prev;
        end
    end

    // todo: prevent multiple fetches/refetching the same thing if stalled

    always_ff @(posedge clk) if (rst) begin
        has_input <= '0;
    end

    always_ff @(posedge clk) if (!rst) begin
        if (!has_input || transfer_next || flush_pipeline) begin
            // try to accept new input
            if (transfer_prev) begin
                program_count_i <= program_count_in;
                program_count_valid_i <= program_count_valid_in;
                
                has_input <= '1;
            end else begin
                has_input <= '0;
            end
        end
    end

endmodule