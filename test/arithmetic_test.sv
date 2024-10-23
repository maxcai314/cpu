`timescale 1ns / 1ps

module arithmetic_test (
    
);

    logic clk;
    logic rst;
    
    logic [31:0] lhs;
    logic lhs_valid;
    
    logic [31:0] rhs;
    logic rhs_valid;
    
    logic [14:12] operation;
    logic operation_valid;
    
    logic [31:25] metadata;
    logic metadata_valid;
    
    logic [31:0] result;
    logic result_valid;
    
    arithmetic arithmetic (
        .clk ( clk ),
        .rst ( rst ),
        
        .lhs ( lhs ),
        .lhs_valid ( lhs_valid ),
        
        .rhs ( rhs ),
        .rhs_valid ( rhs_valid ),
        
        .operation ( operation ),
        .operation_valid ( operation_valid ),
        
        .metadata ( metadata ),
        .metadata_valid ( metadata_valid ),
        
        .result ( result ),
        .result_valid ( result_valid )
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
        
        // invalid operation
        $display("testing invalid operation mode");
        lhs_valid = '1;
        rhs_valid = '1;
        operation_valid = '1;
        metadata_valid = '1;
        lhs = 32'h0000_0000;
        rhs = 32'h0000_0000;
        operation = 3'h0;
        metadata = 7'h01; // invalid metadata
        @(posedge clk)
        assert(!result_valid);
        
        // invalid input
        $display("testing invalid lhs");
        lhs_valid = '0;
        rhs_valid = '1;
        lhs = 32'h0000_0000;
        rhs = 32'h0000_0000;
        operation = 3'h0;
        metadata = 7'h00;
        @(posedge clk)
        assert(!result_valid);
        
        $display("testing invalid rhs");
        lhs_valid = '1;
        rhs_valid = '0;
        lhs = 32'h0000_0000;
        rhs = 32'h0000_0000;
        operation = 3'h0;
        metadata = 7'h00;
        @(posedge clk)
        assert(!result_valid);
        
        $display("testing invalid lhs and rhs");
        lhs_valid = '0;
        rhs_valid = '0;
        lhs = 32'h0000_0000;
        rhs = 32'h0000_0000;
        operation = 3'h0;
        metadata = 7'h00;
        @(posedge clk)
        assert(!result_valid);
        
        $display("testing invalid operation");
        lhs_valid = '1;
        rhs_valid = '1;
        operation_valid = '0;
        metadata_valid = '1;
        lhs = 32'h0000_0000;
        rhs = 32'h0000_0000;
        operation = 3'h0;
        metadata = 7'h00;
        @(posedge clk)
        assert(!result_valid);
        
        $display("testing invalid metadata");
        lhs_valid = '1;
        rhs_valid = '1;
        operation_valid = '1;
        metadata_valid = '0;
        lhs = 32'h0000_0000;
        rhs = 32'h0000_0000;
        operation = 3'h0;
        metadata = 7'h00;
        @(posedge clk)
        assert(!result_valid);
                                
        // addition
        $display("testing addition");
        lhs_valid = '1;
        rhs_valid = '1;
        operation_valid = '1;
        metadata_valid = '1;
        operation = 3'h0;
        metadata = 7'h00;
        lhs = 32'h0000_0000;
        rhs = 32'h0000_0000;
        // should read 0x0000_0000
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'h0000_0000);
        
        lhs = 32'h0000_0001;
        // should read 0x0000_0001
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'h0000_0001);
        
        rhs = 32'h0000_ffff;
        // should read 0x0001_0000
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'h0001_0000);
        
        rhs = 32'hffff_ffff;
        // should read 0x0000_0000 by overflow
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'h0000_0000);
        
        // subtraction
        $display("testing subtraction");
        operation = 3'h0;
        metadata = 7'h20;
        lhs = 32'h0000_0000;
        rhs = 32'h0000_0000;
        // should read 0x0000_0000
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'h0000_0000);
        
        rhs = 32'h0000_0001;
        // should read 0xffff_ffff by underflow
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'hffff_ffff);
        
        lhs = 32'h0001_0000;
        // should read 0x0000_ffff
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'h0000_ffff);
        
        // logical XOR
        $display("testing XOR");
        operation = 3'h4;
        metadata = 7'h00;
        lhs = 32'h1111_ffff;
        rhs = 32'h0204_f0f0;
        // should read 0x1315_0f0f
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'h1315_0f0f);
        
        // logical OR
        $display("testing OR");
        operation = 3'h6;
        metadata = 7'h00;
        lhs = 32'h1020_f171;
        rhs = 32'he0d1_f886;
        // should read 0xf0f1_f9f7
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'hf0f1_f9f7);
        
        // logical AND
        $display("testing AND");
        operation = 3'h7;
        metadata = 7'h00;
        lhs = 32'h0ff8_12a6;
        rhs = 32'hff17_2583;
        // should read 0x0f10_0082
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'h0f10_0082);
        
        // shift left
        $display("testing shift left");
        operation = 3'h1;
        metadata = 7'h00;
        lhs = 32'hf2f8_3107;
        rhs = 32'h0000_0001;
        // should read 0xe5f0_620e
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'he5f0_620e);
        
        lhs = 32'hf2f8_3107;
        rhs = 32'h0000_0000;
        // should read 0xf2f8_3107
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'hf2f8_3107);
        
        lhs = 32'hf2f8_3107;
        rhs = 32'h0000_0004;
        // should read 0x2f83_1070
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'h2f83_1070);
        
        lhs = 32'hf2f8_3107;
        rhs = 32'h0000_0020;
        // should read 0x0000_0000
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'h0000_0000);
        
        // shift right logical
        $display("testing shift right logical");
        operation = 3'h5;
        metadata = 7'h00;
        lhs = 32'h4863_201f;
        rhs = 32'h0000_0001;
        // should read 0x2431_900f
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'h2431_900f);
        
        lhs = 32'h4863_201f;
        rhs = 32'h0000_0000;
        // should read 0x4863_201f
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'h4863_201f);
        
        lhs = 32'h4863_201f;
        rhs = 32'h0000_0004;
        // should read 0x0486_3201
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'h0486_3201);
        
        lhs = 32'h4863_201f;
        rhs = 32'h0000_0020;
        // should read 0x0000_0000
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'h0000_0000);
        
        // shift right arithmetical
        $display("testing shift right arithmetical");
        operation = 3'h5;
        metadata = 7'h20;
        lhs = 32'ha863_201f;
        rhs = 32'h0000_0001;
        // should read 0xd431_900f
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'hd431_900f);
        
        lhs = 32'ha863_201f;
        rhs = 32'h0000_0000;
        // should read 0xa863_201f
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'ha863_201f);
        
        lhs = 32'ha863_201f;
        rhs = 32'h0000_0004;
        // should read 0xf286_3201
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'hfa86_3201);
        
        lhs = 32'ha863_201f;
        rhs = 32'h0000_0020;
        // should read 0xffff_ffff
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'hffff_ffff);
        
        // set less than (signed)
        $display("testing set less than (signed)");
        operation = 3'h2;
        metadata = 7'h00;
        lhs = 32'h0000_0000;
        rhs = 32'hffff_ffff;
        // should read 0x0000_0000
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'h0000_0000);
        
        lhs = 32'hffff_ffff;
        rhs = 32'h0000_0000;
        // should read 0x0000_0001
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'h0000_0001);
        
        lhs = 32'h0000_0000;
        rhs = 32'h0000_0000;
        // should read 0x0000_0000
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'h0000_0000);
        
        // set less than (unsigned)
        $display("testing set less than (unsigned)");
        operation = 3'h3;
        metadata = 7'h00;
        lhs = 32'h0000_0000;
        rhs = 32'hffff_ffff;
        // should read 0x0000_0001
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'h0000_0001);
        
        lhs = 32'hffff_ffff;
        rhs = 32'h0000_0000;
        // should read 0x0000_0000
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'h0000_0000);
        
        lhs = 32'h0000_0000;
        rhs = 32'h0000_0000;
        // should read 0x0000_0000
        @(posedge clk)
        assert(result_valid);
        assert(result == 32'h0000_0000);
    end

endmodule