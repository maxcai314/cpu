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
    input logic write_activate,
    
    output logic write_done, // whether the write will be finished on the next posedge
    
    output logic [DATA_WIDTH - 1:0] instruction_data,
    output logic instruction_fetch_done,
    
    output logic [DATA_WIDTH - 1:0] fetched_data,
    output logic fetch_done,
    
    output logic led_out // ugly
);

    logic [7:0] data [MEM_BYTE_SIZE];
    
    logic [3:0] write_timer; // simulation: only write on every 16th cycle
    
    always_ff @(posedge clk) begin
        if (rst) begin
            write_timer <= '0;
        end else begin
            write_timer <= write_timer + 1;
        end
    end
    
    // todo: use realistic memory; also see if fetch failed
    assign instruction_fetch_done = '1;
    assign fetch_done = '1;
    assign write_done = write_activate && (write_timer == 0); // whether or not the write will happen next cycle
    
    always_ff @(posedge clk) if (rst) begin
//        for (logic [ADDR_WIDTH - 1:0] i=0; i<MEM_BYTE_SIZE; i++)
//            data[i] <= 8'h00;
//         todo: initialize some instructions to run?
        led_out <= '0;
    end
        
    always_ff @(posedge clk) if (!rst && write_done) begin
        for (int unsigned i = 0; i < DATA_BYTE_SIZE; i++) begin
            if (i < bytes_to_write)
                data[write_addr + i] <= write_data[8 * i +:8];
        end
        if (bytes_to_write == DATA_INDEXING_WIDTH'(1) && write_addr == 32'h0000_0fff) begin
            led_out <= write_data != 0;
        end
    end
    
    always_comb begin
        for (int unsigned i = 0; i < DATA_BYTE_SIZE; i++) begin
            instruction_data[8 * i +:8] = data[instruction_addr + i];
            fetched_data[8 * i +:8] = data[fetch_addr + i];
        end
    end

endmodule
