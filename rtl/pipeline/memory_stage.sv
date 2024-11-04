`timescale 1ns / 1ps

// loads or stores
module memory_stage #(
    localparam ADDR_WIDTH = 32,
    localparam DATA_WIDTH = 32,
    localparam INSTRUCTION_WIDTH = 32,
    localparam IMMEDIATE_WIDTH = 32,
    localparam NUM_REGISTERS = 32,
    localparam REGISTER_INDEXING_WIDTH = $clog2(NUM_REGISTERS),
    localparam DATA_BYTE_SIZE = DATA_WIDTH / 8,
    localparam DATA_INDEXING_WIDTH = $clog2(DATA_BYTE_SIZE)
) (
    input logic clk,
    input logic rst,

    output logic stall_prev, // dictates previous stage
    input logic prev_done, // comes from previous stage

    input logic next_stall, // comes from next stage
    output logic done_next, // dictates next stage

    // global interactions
    output logic [ADDR_WIDTH - 1:0] write_addr,
    output logic [DATA_WIDTH - 1:0] write_data,
    output logic write_activate, // assert that write addr and data are valid when using this
    output logic [DATA_INDEXING_WIDTH:0] bytes_to_write,
    input logic write_done,

    output logic [ADDR_WIDTH - 1:0] fetch_addr,
    output logic fetch_activate, // assert that fetch addr is valid when using this
    input logic [DATA_WIDTH - 1:0] fetched_data,
    input logic fetch_done,
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

    input logic [31:25] funct_7_in,
    input logic funct_7_valid_in,
    
    input logic [14:12] funct_3_in,
    input logic funct_3_valid_in,

    input logic [DATA_WIDTH - 1:0] memory_store_data_in,
    input logic memory_store_data_valid_in,

    input logic [REGISTER_INDEXING_WIDTH - 1:0] write_register_in,
    input logic writeback_enabled_in,

    input logic [DATA_WIDTH - 1:0] result_data_in, // register result or effective address
    input logic result_data_valid_in,
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

    output logic [REGISTER_INDEXING_WIDTH - 1:0] write_register_out,
    output logic writeback_enabled_out,

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
    logic [31:25] funct_7_i;
    logic funct_7_valid_i;
    logic [14:12] funct_3_i;
    logic funct_3_valid_i;
    logic [DATA_WIDTH - 1:0] memory_store_data_i;
    logic memory_store_data_valid_i;
    logic [REGISTER_INDEXING_WIDTH - 1:0] write_register_i;
    logic writeback_enabled_i;
    logic [DATA_WIDTH - 1:0] result_data_i;
    logic result_data_valid_i;

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
        write_register_out = write_register_i;
        writeback_enabled_out = writeback_enabled_i;
    end

    always_comb begin
        write_data = memory_store_data_i;

        write_activate = store_i;
        fetch_activate = load_i;

        write_addr = result_data_i;
        fetch_addr = result_data_i;
    end

    always_comb unique case (funct_3_i)
        3'h0 : bytes_to_write = 3'h1; // byte
        3'h1 : bytes_to_write = 3'h2; // half
        3'h2 : bytes_to_write = 3'h4; // word
        
        default : bytes_to_write = 'X;
    endcase

    logic [31:0] load_data;
    always_comb unique case (funct_3_i)
        3'h0 : load_data = $signed(fetched_data[7:0]); // byte
        3'h1 : load_data = $signed(fetched_data[15:0]); // half
        3'h2 : load_data = fetched_data; // word
        3'h4 : load_data = $unsigned(fetched_data[7:0]); // unsigned byte
        3'h5 : load_data = $unsigned(fetched_data[15:0]); // unsigned half
        
        default : load_data = 'X;
    endcase

    // transfer logic
    logic transfer_prev;
    logic transfer_next;
    logic has_input;

    always_comb begin
        if (store_i) begin
            done_next = !rst && has_input && write_done;
            result_data_out = 'X;
            result_data_valid_out = '0;
        end else if (load_i) begin
            done_next = !rst && has_input && fetch_done;
            result_data_out = load_data;
            result_data_valid_out = fetch_done;
        end else begin
            done_next = !rst && has_input; // nothing to wait for
            result_data_out = result_data_i;
            result_data_valid_out = result_data_valid_i;
        end
    end

    always_comb begin
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
                funct_7_i <= funct_7_in;
                funct_7_valid_i <= funct_7_valid_in;
                funct_3_i <= funct_3_in;
                funct_3_valid_i <= funct_3_valid_in;
                memory_store_data_i <= memory_store_data_in;
                memory_store_data_valid_i <= memory_store_data_valid_in;
                write_register_i <= write_register_in;
                writeback_enabled_i <= writeback_enabled_in;
                result_data_i <= result_data_in;
                result_data_valid_i <= result_data_valid_in;

                has_input <= '1;
            end else begin
                has_input <= '0;
            end
        end
    end

endmodule