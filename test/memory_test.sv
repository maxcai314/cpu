`timescale 1ns / 1ps

module memory_test(

);

    logic clk;
    logic rst;
    
    logic [31:0] instruction_addr;
    logic [31:0] fetch_addr;
    
    logic [2:0] bytes_to_write; // zero for no-op
    logic [31:0] write_addr;
    logic [31:0] write_data;
    logic write_data_valid;
    
    logic write_done;
    
    logic [31:0] instruction_data;
    logic [31:0] fetched_data;
    
    memory memory (
        .clk ( clk ),
        .rst ( rst ),
        
        .instruction_addr ( instruction_addr ),
        .fetch_addr ( fetch_addr ),
        
        .bytes_to_write ( bytes_to_write ),
        .write_addr ( write_addr ),
        .write_data ( write_data ),
        .write_data_valid ( write_data_valid ),
        
        .write_done ( write_done ),
        
        .instruction_data ( instruction_data ),
        .fetched_data ( fetched_data )
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
        
        bytes_to_write = 3'd0;
        write_data_valid = '0;
        
        // read from consecuitive words (4 bytes apart)
        instruction_addr = 32'h0100;
        fetch_addr = 32'h0104;
        
        @(posedge clk)
        
        // set to ffff_ffff
        write_addr = 32'h0100;
        write_data = 32'hffff_ffff;
        write_data_valid = '1;
        bytes_to_write = 3'd4;
        
        @(posedge clk)
        assert(write_done);
        assert(instruction_data == 32'hffff_ffff);
        
        // incrementally clear bytes
        write_data = 32'h0000_0000;
        
        // no-op
        write_data_valid = '0;
        @(posedge clk)
        assert(!write_done);
        assert(instruction_data == 32'hffff_ffff);
        // clear lower byte
        bytes_to_write = 3'd1;
        write_data_valid = '1;
        @(posedge clk)
        assert(write_done);
        assert(instruction_data == 32'hffff_ff00);
        // clear lower half
        bytes_to_write = 3'd2;
        @(posedge clk)
        assert(instruction_data == 32'hffff_0000);
        // clear word
        bytes_to_write = 3'd4;
        
        @(posedge clk)
        assert(instruction_data == 32'h0000_0000);
        
        // write to next byte
        write_addr = 32'h0104;
        write_data = 32'hdead_beef;
        bytes_to_write = 3'd4;
        
        @(posedge clk)
        assert(fetched_data == 32'hdead_beef);
        
        // overwrite lower half only
        write_data = 32'hb0ba_cafe;
        bytes_to_write = 3'd2;
        
        // should read 0xdead_cafe
        
        @(posedge clk)
        assert(fetched_data == 32'hdead_cafe);
        @(posedge clk)
        @(posedge clk)
        
        // test address endianess
        write_addr = 32'h0100;
        write_data = 32'h0000_0000;
        bytes_to_write = 3'd4;
        @(posedge clk)
        write_addr = 32'h0101;
        write_data = 32'haabb_ccdd;
        // should read 0xbbcc_dd00
 
        @(posedge clk)
        assert(instruction_data == 32'hbbcc_dd00);
        @(posedge clk)
        @(posedge clk)
        
        // load in test image
        bytes_to_write = 3'd0;
        instruction_addr = 32'h0000; // should read 0xdead_beef
        fetch_addr = 32'h0004; // should read 0xaabb_ccdd
        rst = '1;
        $readmemh("test_image.mem", memory.data);
        @(posedge clk)
        rst = '0;
        @(posedge clk)
        fetch_addr = 32'h0008; // should read 0xffff_ffff
        @(posedge clk)
        assert(fetched_data == 32'hffff_ffff);
        
        fetch_addr = 32'h000c; // should read 0x0000_0000
        @(posedge clk)
        assert(fetched_data == 32'h0000_0000);
    end
    
endmodule
