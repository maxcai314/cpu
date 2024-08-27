`timescale 1ns / 1ps

module registers_test (
    
);

    logic clk;
    logic rst;
    
    logic [4:0] read_register_1;
    logic [4:0] read_register_2;
    
    logic [31:0] result_1;
    logic [31:0] result_2;
    
    logic [4:0] write_register;
    logic [31:0] write_data;
    
    registers registers (
        .clk ( clk ),
        .rst ( rst ),
        
        .read_register_1 ( read_register_1 ),
        .read_register_2 ( read_register_2 ),
        
        .result_1 ( result_1 ),
        .result_2 ( result_2 ),
        
        .write_register ( write_register ),
        .write_data ( write_data )
    );
    
    initial forever begin
        clk = '1;
        #5;
        clk = '0;
        #5;
    end
    
    initial begin
        // initialize
        #15;
        @(posedge clk)
        rst = 1;
        @(posedge clk)
        rst = 0;
        
        // display zero and one register
        read_register_1 = 5'b00000;
        read_register_2 = 5'b00001;
        
        @(posedge clk)
        
        // try to write to zero
        write_register = 5'b00000;
        write_data = 32'hffff_ffff;
        
        @(posedge clk)
        
        // try to write to one
        write_register = 5'b00001;
        write_data = 32'hffff_ffff;
        
        @(posedge clk)
        
        write_data = 32'hdead_beef;
    end

endmodule