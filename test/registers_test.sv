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
    logic write_activate;
    
    logic write_done;
    
    registers registers (
        .clk ( clk ),
        .rst ( rst ),
        
        .read_register_1 ( read_register_1 ),
        .read_register_2 ( read_register_2 ),
        
        .result_1 ( result_1 ),
        .result_2 ( result_2 ),
        
        .write_register ( write_register ),
        .write_data ( write_data ),
        .write_activate ( write_activate ),
        
        .write_done ( write_done )
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
        assert(result_1 == 32'h0000_0000);
        assert(result_2 == 32'h0000_0000);
        
        // try to write to zero
        write_register = 5'b00000;
        write_data = 32'hffff_ffff;
        write_activate = '1;
        
        @(posedge clk)
        assert(write_done);
        assert(result_1 == 32'h0000_0000);
        
        // try to write to one
        write_register = 5'b00001;
        write_data = 32'hffff_ffff;
        
        @(posedge clk)
        assert(write_done);
        assert(result_2 == 32'hffff_ffff);
        
        write_data = 32'hdead_beef;
        
        @(posedge clk)
        assert(write_done);
        assert(result_2 == 32'hdead_beef);
        
        // disable write
        write_data = 32'haabb_ccdd;
        write_activate = '0;
        
        @(posedge clk)
        assert(!write_done);
        assert(result_2 == 32'hdead_beef);
        assert(result_2 != 32'haabb_ccdd);
        
        @(posedge clk)
        assert(!write_done);
        assert(result_2 == 32'hdead_beef);
        assert(result_2 != 32'haabb_ccdd);
    end

endmodule