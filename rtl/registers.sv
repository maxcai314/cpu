`timescale 1ns / 1ps

module registers #(
    parameter DATA_WIDTH = 32,
    localparam NUM_REGISTERS = 32,
    localparam REGISTER_INDEXING_WIDTH = $clog2(NUM_REGISTERS)
) (
    input logic clk,
    input logic rst,
    
    input logic [REGISTER_INDEXING_WIDTH - 1:0] read_register_1,
    input logic [REGISTER_INDEXING_WIDTH - 1:0] read_register_2,
    
    input logic [REGISTER_INDEXING_WIDTH - 1:0] write_register, // zero for no-op
    input logic [DATA_WIDTH - 1:0] write_data,
    
    output logic [DATA_WIDTH - 1:0] result_1,
    output logic [DATA_WIDTH - 1:0] result_2
);

    logic [DATA_WIDTH - 1:0] data [NUM_REGISTERS];
    
    assign data[0] = DATA_WIDTH'(0); // zero register
    
    assign result_1 = data[read_register_1];
    assign result_2 = data[read_register_2];
    
    always_ff @(posedge clk) if (rst) begin
        for (int i = 1; i < NUM_REGISTERS; i++)
            data[i] <= DATA_WIDTH'(0); // reset registers
    end
    
    always_ff @(posedge clk) if (!rst) begin
        if (write_register != 0)
            data[write_register] <= write_data;
    end

endmodule
