`timescale 1ns / 1ps

// a single-cycle cpu
module cpu(
    input logic clk,
    input logic rst
);
    logic [31:0] program_count;
    logic [31:0] instruction_data;

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
    logic opcode_valid;
    
    logic [31:0] immediate_data;
    logic immediate_valid;
    
    logic [19:15] register_1;
    logic register_1_valid;
    
    logic [24:20] register_2;
    logic register_2_valid;
    
    logic [11:7] decoded_write_register;
    logic write_register_valid;
    
    logic [31:25] funct_7;
    logic funct_7_valid;
    
    logic [14:12] funct_3;
    logic funct_3_valid;
    
    decoder decoder (
        .clk ( clk ),
        .rst ( rst ),
        
        .instruction_data ( instruction_data ),
        
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
        .opcode_valid ( opcode_valid ),
        
        .immediate_data ( immediate_data ),
        .immediate_valid ( immediate_valid ),
        
        .register_1 ( register_1 ),
        .register_1_valid ( register_1_valid ),
        
        .register_2 ( register_2 ),
        .register_2_valid ( register_2_valid ),
        
        .write_register ( decoded_write_register ),
        .write_register_valid ( write_register_valid ),
        
        .funct_7 ( funct_7 ),
        .funct_7_valid ( funct_7_valid ),
        
        .funct_3 ( funct_3 ),
        .funct_3_valid ( funct_3_valid )
    );
        
    logic [31:0] register_result_1;
    logic [31:0] register_result_2;
    
    logic [4:0] write_register;
    logic [31:0] write_register_data;
    
    registers registers (
        .clk ( clk ),
        .rst ( rst ),
        
        .read_register_1 ( register_1 ),
        .read_register_2 ( register_2 ),
        
        .result_1 ( register_result_1 ),
        .result_2 ( register_result_2 ),
        
        .write_register ( write_register ),
        .write_data ( write_register_data )
    );
    
    logic [31:0] fetch_addr;
    
    logic [2:0] bytes_to_write; // zero for no-op
    logic [31:0] write_addr;
    logic [31:0] write_data;
    
    logic [31:0] fetched_data;
    
    memory memory (
        .clk ( clk ),
        .rst ( rst ),
        
        .instruction_addr ( program_count ),
        .fetch_addr ( fetch_addr ),
        
        .bytes_to_write ( bytes_to_write ),
        .write_addr ( write_addr ),
        .write_data ( write_data ),
        
        .instruction_data ( instruction_data ),
        .fetched_data ( fetched_data )
    );
    
    logic [31:0] lhs;
    logic [31:0] rhs;
    
    logic [31:0] arithmetic_result;
    logic arithmetic_valid;
    
    arithmetic arithmetic (
        .clk ( clk ),
        .rst ( rst ),
        
        .lhs ( lhs ),
        .rhs ( rhs ),
        
        .operation ( funct_3 ),
        .metadata ( funct_7 ),
        
        .result ( arithmetic_result ),
        .valid ( arithmetic_valid )
    );
    
    logic [31:0] working_address;
    assign working_address = register_result_1 + immediate_data; // for both load and store
    assign fetch_addr = working_address; // for now, until we need to worry about constantly fetching
    assign write_addr = working_address; // for now, until we need to worry about constantly writing 0 bytes
    
    assign lhs = register_result_1;
    assign rhs = immediate_arith ? immediate_data : register_result_2;
    assign write_register = write_register_valid ? decoded_write_register : 5'h0000_0000; // todo: wrong
    
    logic [31:0] load_data;
    always_comb unique case (funct_3)
        3'h0 : load_data = $signed(fetched_data[7:0]); // byte
        3'h1 : load_data = $signed(fetched_data[15:0]); // half
        3'h2 : load_data = fetched_data; // word
        3'h4 : load_data = $unsigned(fetched_data[7:0]); // unsigned byte
        3'h5 : load_data = $unsigned(fetched_data[15:0]); // unsigned half
        
        default : load_data = 'X;
    endcase
    
    logic [2:0] bytes_to_store;
    always_comb unique case (funct_3)
        3'h0 : bytes_to_store = 3'h1; // byte
        3'h1 : bytes_to_store = 3'h2; // half
        3'h2 : bytes_to_store = 3'h4; // word
        
        default : bytes_to_store = 'X;
    endcase
    
    assign bytes_to_write = store ? bytes_to_store : 3'h0;
    assign write_data = register_result_2;
    
    logic [31:0] next_instruction;
    logic branch_operation_valid;
    
    count count (
        .clk ( clk ),
        .rst ( rst ),
        
        .lhs ( register_result_1 ),
        .rhs ( register_result_2 ),
        .operation ( funct_3 ),
        
        .immediate_offset ( immediate_data ),
        .register_address ( register_result_1 ),
        
        .branch ( branch ),
        .immediate_jump ( immediate_jump ),
        .register_jump ( register_jump ),
        
        .program_count ( program_count ),
        .next_instruction ( next_instruction ),
        .operation_valid ( branch_operation_valid )
    );
    
    always_comb begin
        if (register_arith || immediate_arith)
            write_register_data = arithmetic_result;
        else if (load)
            write_register_data = load_data;
        else if (immediate_jump || register_jump)
            write_register_data = next_instruction;
        else if (load_upper)
            write_register_data = immediate_data;
        else if (load_upper_pc)
            write_register_data = program_count + immediate_data; // todo: use alu
        else
            write_register_data = 'X;
    end

endmodule
