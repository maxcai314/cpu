`timescale 1ns / 1ps

// a five-cycle cpu
module five_cycle_cpu (
    input logic clk,
    input logic rst
);
    
    logic [4:0] read_register_1;
    logic [4:0] read_register_2;
    
    logic [31:0] register_result_1;
    logic [31:0] register_result_2;

    logic register_read_1_contended;
    logic register_read_2_contended;

    assign register_read_1_contended = '0;
    assign register_read_2_contended = '0; // for now

    logic [4:0] write_register;
    logic [31:0] write_register_data;
    logic write_register_activate;
    logic register_write_done;
    

    registers registers (
        .clk ( clk ),
        .rst ( rst ),
        
        .read_register_1 ( read_register_1 ),
        .read_register_2 ( read_register_2 ),
        
        .result_1 ( register_result_1 ),
        .result_2 ( register_result_2 ),
        
        .write_register ( write_register ),
        .write_data ( write_register_data ),
        .write_activate ( write_register_activate ),
        
        .write_done ( register_write_done )
    );

    logic [31:0] ram_instruction_fetch_addr;
    logic ram_instruction_fetch_activate; // unused for now
    logic [31:0] ram_instruction_data;
    logic ram_instruction_fetch_done;

    logic [31:0] memory_fetch_addr;
    logic memory_fetch_activate;
    logic [31:0] memory_fetched_data;
    logic memory_fetch_done;

    logic [2:0] memory_bytes_to_write;
    logic [31:0] memory_write_addr;
    logic [31:0] memory_write_data;
    logic memory_write_activate;
    logic memory_write_done;

    memory memory (
        .clk ( clk ),
        .rst ( rst ),
        
        .instruction_addr ( ram_instruction_fetch_addr ),
        .fetch_addr ( memory_fetch_addr ),
        
        .bytes_to_write ( memory_bytes_to_write ),
        .write_addr ( memory_write_addr ),
        .write_data ( memory_write_data ),
        .write_activate ( memory_write_activate ),
        .write_done ( memory_write_done ),
        
        .instruction_data ( ram_instruction_data ),
        .instruction_fetch_done ( ram_instruction_fetch_done ), // todo: implement in memory handler
        
        .fetched_data ( memory_fetched_data ),
        .fetch_done ( memory_fetch_done )
    );

    logic [31:0] program_count;
    logic program_count_valid;

    logic fetch_stall; // whether fetch can accept a new input
    logic program_count_done; // whether we have something to give to stall

    logic decode_stall;
    logic fetch_done;

    logic [31:0] fetch_program_count;
    logic fetch_program_count_valid;
    logic [31:0] fetch_instruction_data;
    logic fetch_instruction_data_valid;

    fetch_stage fetch_stage (
        .clk ( clk ),
        .rst ( rst ),

        .stall_prev ( fetch_stall ),
        .prev_done ( program_count_done ),

        .next_stall ( decode_stall ),
        .done_next ( fetch_done ),

        .instruction_addr ( ram_instruction_fetch_addr ),
        .instruction_fetch_activate ( ram_instruction_fetch_activate ),
        .instruction_data ( ram_instruction_data ),
        .instruction_fetch_done ( ram_instruction_fetch_done ),
        
        .program_count_in ( program_count ),
        .program_count_valid_in ( program_count_valid ),

        .program_count_out ( fetch_program_count ),
        .program_count_valid_out ( fetch_program_count_valid ),
        .instruction_data_out ( fetch_instruction_data ),
        .instruction_data_valid_out ( fetch_instruction_data_valid )
    );

    logic execute_stall;
    logic decode_done;

    logic decode_control_flow_affected;
    logic [31:0] decode_jump_target;
    logic decode_jump_target_valid;

    logic [31:0] decode_program_count;
    logic decode_program_count_valid;
    logic decode_register_arith;
    logic decode_immediate_arith;
    logic decode_load;
    logic decode_store;
    logic decode_branch;
    logic decode_immediate_jump;
    logic decode_register_jump;
    logic decode_load_upper;
    logic decode_load_upper_pc;
    logic decode_environment;
    logic decode_opcode_legal;
    logic [31:0] decode_immediate_data;
    logic decode_immediate_data_valid;
    logic [31:0] decode_register_1_data;
    logic decode_register_1_data_valid;
    logic [31:0] decode_register_2_data;
    logic decode_register_2_data_valid;
    logic [4:0] decode_write_register;
    logic decode_writeback_enabled;
    logic [31:25] decode_funct_7;
    logic decode_funct_7_valid;
    logic [14:12] decode_funct_3;
    logic decode_funct_3_valid;

    decode_stage decode_stage (
        .clk ( clk ),
        .rst ( rst ),

        .stall_prev ( decode_stall ),
        .prev_done ( fetch_done ),
        .next_stall ( execute_stall ),
        .done_next ( decode_done ),

        .register_read_1 ( read_register_1 ),
        .register_read_1_data ( register_result_1 ),
        .register_read_1_contended ( register_read_1_contended ),
        .register_read_2 ( read_register_2 ),
        .register_read_2_data ( register_result_2 ),
        .register_read_2_contended ( register_read_2_contended ),

        .control_flow_affected ( decode_control_flow_affected ),
        .jump_target ( decode_jump_target ),
        .jump_target_valid ( decode_jump_target_valid ),

        .program_count_in ( fetch_program_count ),
        .program_count_valid_in ( fetch_program_count_valid ),
        .instruction_data_in ( fetch_instruction_data ),
        .instruction_data_valid_in ( fetch_instruction_data_valid ),

        .program_count_out ( decode_program_count ),
        .program_count_valid_out ( decode_program_count_valid ),
        .register_arith_out ( decode_register_arith ),
        .immediate_arith_out ( decode_immediate_arith ),
        .load_out ( decode_load ),
        .store_out ( decode_store ),
        .branch_out ( decode_branch ),
        .immediate_jump_out ( decode_immediate_jump ),
        .register_jump_out ( decode_register_jump ),
        .load_upper_out ( decode_load_upper ),
        .load_upper_pc_out ( decode_load_upper_pc ),
        .environment_out ( decode_environment ),
        .opcode_legal_out ( decode_opcode_legal ),
        .immediate_data_out ( decode_immediate_data ),
        .immediate_data_valid_out ( decode_immediate_data_valid ),
        .register_1_data_out ( decode_register_1_data ),
        .register_1_data_valid_out ( decode_register_1_data_valid ),
        .register_2_data_out ( decode_register_2_data ),
        .register_2_data_valid_out ( decode_register_2_data_valid ),
        .write_register_out ( decode_write_register ),
        .writeback_enabled_out ( decode_writeback_enabled ),
        .funct_7_out ( decode_funct_7 ),
        .funct_7_valid_out ( decode_funct_7_valid ),
        .funct_3_out ( decode_funct_3 ),
        .funct_3_valid_out ( decode_funct_3_valid )
    );

    logic memory_stall;
    logic execute_done;

    logic [31:0] execute_program_count;
    logic execute_program_count_valid;
    logic execute_register_arith;
    logic execute_immediate_arith;
    logic execute_load;
    logic execute_store;
    logic execute_branch;
    logic execute_immediate_jump;
    logic execute_register_jump;
    logic execute_load_upper;
    logic execute_load_upper_pc;
    logic execute_environment;
    logic execute_opcode_legal;
    logic [31:25] execute_funct_7;
    logic execute_funct_7_valid;
    logic [14:12] execute_funct_3;
    logic execute_funct_3_valid;
    logic [31:0] execute_memory_store_data;
    logic execute_memory_store_data_valid;
    logic [4:0] execute_write_register;
    logic execute_writeback_enabled;
    logic [31:0] execute_result_data;
    logic execute_result_data_valid;

    execute_stage execute_stage (
        .clk ( clk ),
        .rst ( rst ),

        .stall_prev ( execute_stall ),
        .prev_done ( decode_done ),
        .next_stall ( memory_stall ),
        .done_next ( execute_done ),

        .program_count_in ( decode_program_count ),
        .program_count_valid_in ( decode_program_count_valid ),
        .register_arith_in ( decode_register_arith ),
        .immediate_arith_in ( decode_immediate_arith ),
        .load_in ( decode_load ),
        .store_in ( decode_store ),
        .branch_in ( decode_branch ),
        .immediate_jump_in ( decode_immediate_jump ),
        .register_jump_in ( decode_register_jump ),
        .load_upper_in ( decode_load_upper ),
        .load_upper_pc_in ( decode_load_upper_pc ),
        .environment_in ( decode_environment ),
        .opcode_legal_in ( decode_opcode_legal ),
        .immediate_data_in ( decode_immediate_data ),
        .immediate_data_valid_in ( decode_immediate_data_valid ),
        .register_1_data_in ( decode_register_1_data ),
        .register_1_data_valid_in ( decode_register_1_data_valid ),
        .register_2_data_in ( decode_register_2_data ),
        .register_2_data_valid_in ( decode_register_2_data_valid ),
        .write_register_in ( decode_write_register ),
        .writeback_enabled_in ( decode_writeback_enabled ),
        .funct_7_in ( decode_funct_7 ),
        .funct_7_valid_in ( decode_funct_7_valid ),
        .funct_3_in ( decode_funct_3 ),
        .funct_3_valid_in ( decode_funct_3_valid ),

        .program_count_out ( execute_program_count ),
        .program_count_valid_out ( execute_program_count_valid ),
        .register_arith_out ( execute_register_arith ),
        .immediate_arith_out ( execute_immediate_arith ),
        .load_out ( execute_load ),
        .store_out ( execute_store ),
        .branch_out ( execute_branch ),
        .immediate_jump_out ( execute_immediate_jump ),
        .register_jump_out ( execute_register_jump ),
        .load_upper_out ( execute_load_upper ),
        .load_upper_pc_out ( execute_load_upper_pc ),
        .environment_out ( execute_environment ),
        .opcode_legal_out ( execute_opcode_legal ),
        .funct_7_out ( execute_funct_7 ),
        .funct_7_valid_out ( execute_funct_7_valid ),
        .funct_3_out ( execute_funct_3 ),
        .funct_3_valid_out ( execute_funct_3_valid ),
        .memory_store_data_out ( execute_memory_store_data ),
        .memory_store_data_valid_out ( execute_memory_store_data_valid ),
        .write_register_out ( execute_write_register ),
        .writeback_enabled_out ( execute_writeback_enabled ),
        .result_data_out ( execute_result_data ),
        .result_data_valid_out ( execute_result_data_valid )
    );

    logic writeback_stall;
    logic memory_done;

    logic [31:0] memory_program_count;
    logic memory_program_count_valid;
    logic memory_register_arith;
    logic memory_immediate_arith;
    logic memory_load;
    logic memory_store;
    logic memory_branch;
    logic memory_immediate_jump;
    logic memory_register_jump;
    logic memory_load_upper;
    logic memory_load_upper_pc;
    logic memory_environment;
    logic memory_opcode_legal;
    logic [4:0] memory_write_register;
    logic memory_writeback_enabled;
    logic [31:0] memory_result_data;
    logic memory_result_data_valid;

    memory_stage memory_stage (
        .clk ( clk ),
        .rst ( rst ),

        .stall_prev ( memory_stall ),
        .prev_done ( execute_done ),
        .next_stall ( writeback_stall ),
        .done_next ( memory_done ),
        
        .write_addr ( memory_write_addr ),
        .write_data ( memory_write_data ),
        .write_activate ( memory_write_activate ),
        .bytes_to_write ( memory_bytes_to_write ),
        .write_done ( memory_write_done ),

        .fetch_addr ( memory_fetch_addr ),
        .fetch_activate ( memory_fetch_activate ),
        .fetched_data ( memory_fetched_data ),
        .fetch_done ( memory_fetch_done ),

        .program_count_in ( execute_program_count ),
        .program_count_valid_in ( execute_program_count_valid ),
        .register_arith_in ( execute_register_arith ),
        .immediate_arith_in ( execute_immediate_arith ),
        .load_in ( execute_load ),
        .store_in ( execute_store ),
        .branch_in ( execute_branch ),
        .immediate_jump_in ( execute_immediate_jump ),
        .register_jump_in ( execute_register_jump ),
        .load_upper_in ( execute_load_upper ),
        .load_upper_pc_in ( execute_load_upper_pc ),
        .environment_in ( execute_environment ),
        .opcode_legal_in ( execute_opcode_legal ),
        .funct_7_in ( execute_funct_7 ),
        .funct_7_valid_in ( execute_funct_7_valid ),
        .funct_3_in ( execute_funct_3 ),
        .funct_3_valid_in ( execute_funct_3_valid ),
        .memory_store_data_in ( execute_memory_store_data ),
        .memory_store_data_valid_in ( execute_memory_store_data_valid ),
        .write_register_in ( execute_write_register ),
        .writeback_enabled_in ( execute_writeback_enabled ),
        .result_data_in ( execute_result_data ),
        .result_data_valid_in ( execute_result_data_valid ),

        .program_count_out ( memory_program_count ),
        .program_count_valid_out ( memory_program_count_valid ),
        .register_arith_out ( memory_register_arith ),
        .immediate_arith_out ( memory_immediate_arith ),
        .load_out ( memory_load ),
        .store_out ( memory_store ),
        .branch_out ( memory_branch ),
        .immediate_jump_out ( memory_immediate_jump ),
        .register_jump_out ( memory_register_jump ),
        .load_upper_out ( memory_load_upper ),
        .load_upper_pc_out ( memory_load_upper_pc ),
        .environment_out ( memory_environment ),
        .opcode_legal_out ( memory_opcode_legal ),
        .write_register_out ( memory_write_register ),
        .writeback_enabled_out ( memory_writeback_enabled ),
        .result_data_out ( memory_result_data ),
        .result_data_valid_out ( memory_result_data_valid )
    );

    logic program_count_stall;
    logic writeback_done;

    logic [31:0] writeback_program_count;
    logic writeback_program_count_valid;

    writeback_stage writeback_stage (
        .clk ( clk ),
        .rst ( rst ),

        .stall_prev ( writeback_stall ),
        .prev_done ( memory_done ),
        .next_stall ( program_count_stall ),
        .done_next ( writeback_done ),

        .write_register ( write_register ),
        .write_data ( write_register_data ),
        .write_activate ( write_register_activate ),

        .program_count_in ( memory_program_count ),
        .program_count_valid_in ( memory_program_count_valid ),
        .register_arith_in ( memory_register_arith ),
        .immediate_arith_in ( memory_immediate_arith ),
        .load_in ( memory_load ),
        .store_in ( memory_store ),
        .branch_in ( memory_branch ),
        .immediate_jump_in ( memory_immediate_jump ),
        .register_jump_in ( memory_register_jump ),
        .load_upper_in ( memory_load_upper ),
        .load_upper_pc_in ( memory_load_upper_pc ),
        .environment_in ( memory_environment ),
        .opcode_legal_in ( memory_opcode_legal ),
        .write_register_in ( memory_write_register ),
        .writeback_enabled_in ( memory_writeback_enabled ),
        .result_data_in ( memory_result_data ),
        .result_data_valid_in ( memory_result_data_valid ),

        .program_count_out ( writeback_program_count ),
        .program_count_valid_out ( writeback_program_count_valid )
    );

    logic queued_program_count;
    logic start_program_count; // whether we will transfer a program count into pipeline
    logic finish_program_count; // whether we will transfer a program count out of pipeline

    logic control_flow_affected;
    logic [31:0] jump_target;

    always_comb begin
        program_count_done = !rst && queued_program_count;
        start_program_count = program_count_done && !fetch_stall;
        
        program_count_stall = rst;

        finish_program_count = writeback_done && !program_count_stall;
    end

    always_ff @(posedge clk) if (rst) begin
        program_count <= '0;
        queued_program_count <= '1;
    end

    always_ff @(posedge clk) if (!rst) begin
        if (start_program_count) begin
            queued_program_count <= '0;
        end
    end

    always_ff @(posedge clk) if (!rst) begin
        if (finish_program_count) begin
            if (!control_flow_affected) begin
                program_count <= writeback_program_count + 32'h0000_0004;
                queued_program_count <= '1;
            end else begin
                program_count <= jump_target;
                queued_program_count <= '1;
            end
        end
    end

    // todo: doesn't work when parallel yet
    always_ff @(posedge clk) if (!rst) begin
        if (decode_done && !execute_stall) begin // todo: is && !execute_stall necessary?
            control_flow_affected <= decode_control_flow_affected;
            jump_target <= decode_jump_target;
        end
    end
endmodule