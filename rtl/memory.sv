`timescale 1ns / 1ps

module memory #(
    parameter ADDR_WIDTH = 32, DATA_WIDTH = 32, MEM_BYTE_SIZE = 64'h1000,
    localparam DATA_BYTE_SIZE = DATA_WIDTH / 8,
    localparam DATA_INDEXING_WIDTH = $clog2(DATA_BYTE_SIZE)
) (
    input logic clk,
    input logic rst,
    
    input logic [ADDR_WIDTH - 1:0] instruction_addr,
    input logic [ADDR_WIDTH - 1:0] fetch_addr,
    
    input logic [DATA_INDEXING_WIDTH:0] bytes_to_write,
    input logic [ADDR_WIDTH - 1:0] write_addr,
    input logic [DATA_WIDTH - 1:0] write_data,
    input logic write_data_valid,
    
    output logic write_done, // whether the write will be finished on the next posedge
    
    output logic [DATA_WIDTH - 1:0] instruction_data,
    output logic instruction_fetch_done,
    
    output logic [DATA_WIDTH - 1:0] fetched_data,
    output logic fetch_done
);

    logic [7:0] data [MEM_BYTE_SIZE];
    
    // todo: use realistic memory; also see if fetch failed
    assign instruction_fetch_done = '1;
    assign fetch_done = '1;
    assign write_done = write_data_valid; // todo: add delays
    
    always_ff @(posedge clk) if (rst) begin
//        for (logic [ADDR_WIDTH - 1:0] i=0; i<MEM_BYTE_SIZE; i++)
//            data[i] = 8'h00;
//         todo: initialize some instructions to run?
    end
        
    always_ff @(posedge clk) if (!rst && write_data_valid) begin
        for (int unsigned i = 0; i < DATA_BYTE_SIZE; i++) begin
            if (i < bytes_to_write)
                data[write_addr + i] <= write_data[8 * i +:8];
        end
    end
    
    always_comb begin
        for (int unsigned i = 0; i < DATA_BYTE_SIZE; i++) begin
            instruction_data[8 * i +:8] = data[instruction_addr + i];
            fetched_data[8 * i +:8] = data[fetch_addr + i];
        end
    end

endmodule
