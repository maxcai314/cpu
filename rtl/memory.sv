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
    
    input logic [DATA_INDEXING_WIDTH - 1:0] largest_byte_index,
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

    logic has_write;
    logic [ADDR_WIDTH - 1:0] write_addr_i;
    logic [DATA_WIDTH - 1:0] write_data_i;
    logic [DATA_INDEXING_WIDTH:0] largest_byte_index_i;
    
    // todo: use realistic memory; also see if fetch failed
    assign instruction_fetch_done = '1;
    assign fetch_done = '1;
    assign write_done = has_write && largest_byte_index_i == 0; // whether or not the write will happen next cycle
    
    always_ff @(posedge clk) if (rst) begin
        led_out <= '0;
        
        has_write <= '0;
        write_addr_i <= '0;
        write_data_i <= '0;
        largest_byte_index_i <= '0;
    end else begin
        if (has_write) begin
            data[write_addr_i +: largest_byte_index_i] <= write_data_i;[8 * largest_byte_index_i +:8];
            largest_byte_index_i <= largest_byte_index_i - 1;

            if (largest_byte_index == 0 && write_addr == 32'h0000_0fff) begin
            led_out <= write_data != 0;
        end
        end

        if (!has_write || write_done) begin
            // try to accept new input
            if (write_activate) begin
                write_addr_i <= write_addr;
                write_data_i <= write_data;
                largest_byte_index_i <= largest_byte_index;
                
                has_write <= '1;
            end else begin
                has_write <= '0;
            end
        end
    end
    
    always_comb begin
        for (int unsigned i = 0; i < DATA_BYTE_SIZE; i++) begin
            instruction_data[8 * i +:8] = data[instruction_addr + i];
            fetched_data[8 * i +:8] = data[fetch_addr + i];
        end
    end
    
        
    initial begin
        $readmemh("blink_led.mem", data);
    end

endmodule
