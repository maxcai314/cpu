`timescale 1ns / 1ps

// a five-cycle cpu
module five_cycle_cpu (
    input logic clk,
    input logic rst
);
    


    registers registers (
        .clk ( clk ),
        .rst ( rst ),
        
        .read_register_1 ( register_1 ),
        .read_register_2 ( register_2 ),
        
        .result_1 ( register_result_1 ),
        .result_2 ( register_result_2 ),
        
        .write_register ( write_register ),
        .write_data ( write_register_data ),
        .write_data_valid ( write_register_data_valid ),
        
        .write_valid ( register_write_valid )
    );

endmodule