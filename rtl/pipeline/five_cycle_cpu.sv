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

    logic [31:0] memory_instruction_fetch_addr;
    logic memory_instruction_fetch_activate; // unused for now
    logic [31:0] memory_instruction_data;
    logic memory_instruction_fetch_done;

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
        
        .instruction_addr ( memory_instruction_fetch_addr ),
        .fetch_addr ( memory_fetch_addr ),
        
        .bytes_to_write ( memory_bytes_to_write ),
        .write_addr ( memory_write_addr ),
        .write_data ( memory_write_data ),
        .write_activate ( memory_write_activate ),
        .write_done ( memory_write_done ),
        
        .instruction_data ( memory_instruction_data ),
        .instruction_fetch_done ( memory_instruction_fetch_done ), // todo: implement in memory handler
        
        .fetched_data ( memory_fetched_data ),
        .fetch_done ( memory_fetch_done )
    );

endmodule