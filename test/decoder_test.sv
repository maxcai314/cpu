`timescale 1ns / 1ps

module decoder_test(

);
    logic clk;
    logic rst;
    
    logic [31:0] instruction_data;
    logic instruction_data_valid;
    
    logic register_arith;
    logic immediate_arith;
    logic load;
    logic store;
    logic branch;
    logic immediate_jump;
    logic register_jump;
    logic load_upper;
    logic load_upper_pc;
    logic environment;
    logic opcode_legal;
    
    logic [31:0] immediate_data;
    logic immediate_valid;
    
    logic [19:15] register_1;
    logic register_1_valid;
    
    logic [24:20] register_2;
    logic register_2_valid;
    
    logic [11:7] write_register;
    logic write_register_valid;
    
    logic [31:25] funct_7;
    logic funct_7_valid;
    
    logic [14:12] funct_3;
    logic funct_3_valid;
    
    decoder decoder (
        .instruction_data ( instruction_data ),
        .instruction_data_valid ( instruction_data_valid ),
        
        .register_arith ( register_arith ),
        .immediate_arith ( immediate_arith ),
        .load ( load ),
        .store ( store ),
        .branch ( branch ),
        .immediate_jump ( immediate_jump ),
        .register_jump ( register_jump ),
        .load_upper ( load_upper ),
        .load_upper_pc ( load_upper_pc ),
        .environment ( environment ),
        .opcode_legal ( opcode_legal ),
        
        .immediate_data ( immediate_data ),
        .immediate_valid ( immediate_valid ),
        
        .register_1 ( register_1 ),
        .register_1_valid ( register_1_valid ),
        
        .register_2 ( register_2 ),
        .register_2_valid ( register_2_valid ),
        
        .write_register ( write_register ),
        .write_register_valid ( write_register_valid ),
        
        .funct_7 ( funct_7 ),
        .funct_7_valid ( funct_7_valid ),
        
        .funct_3 ( funct_3 ),
        .funct_3_valid ( funct_3_valid )
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
        
        // addi x15, x0, 23
        instruction_data = 32'h0170_0793;
        instruction_data_valid = '1;
        @(posedge clk)
        assert(!register_arith);
        assert(immediate_arith);
        assert(!load);
        assert(!store);
        assert(!branch);
        assert(!immediate_jump);
        assert(!register_jump);
        assert(!load_upper);
        assert(!load_upper_pc);
        assert(!environment);
        assert(opcode_legal);
        
        assert(immediate_data == 32'h0000_0017); // 23
        assert(immediate_valid);
        
        assert(register_1 == 5'h00); // x0
        assert(register_1_valid);
        
        assert(!register_2_valid);
        
        assert(write_register == 5'h0f); // x15
        assert(write_register_valid);
        
        assert(funct_3 == 3'h0); // add
        assert(funct_3_valid);
        
        assert(funct_7 == 7'h00); // add
        assert(funct_7_valid);
        
        // invalid
        @(posedge clk)
        instruction_data_valid = '0;
        @(posedge clk)
        assert(!opcode_legal);
        assert(!register_arith);
        assert(!immediate_arith);
        assert(!load);
        assert(!store);
        assert(!branch);
        assert(!immediate_jump);
        assert(!register_jump);
        assert(!load_upper);
        assert(!load_upper_pc);
        assert(!environment);
        
        assert(!funct_3_valid);
        assert(!funct_7_valid);
        
        assert(!register_1_valid);
        assert(!register_2_valid);
        assert(!write_register_valid);
    end
    
endmodule
