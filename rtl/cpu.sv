`timescale 1ns / 1ps

// a single-cycle cpu
module cpu(
    input logic clk,
    input logic rst
);
    logic [31:0] program_count;
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
    logic opcode_valid;
    
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
        .clk ( clk ),
        .rst ( rst ),
        
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
        .opcode_valid ( opcode_valid ),
        
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
        
    logic [31:0] register_result_1;
    logic [31:0] register_result_2;
    
    logic [31:0] write_register_data;
    logic write_register_data_valid;
    
    logic register_write_valid;
    
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
    
    logic [31:0] fetch_addr;
    
    logic [2:0] bytes_to_write; // zero for no-op
    logic [31:0] write_addr;
    logic [31:0] write_data;
    logic write_data_valid;
    
    logic write_done;
    
    logic [31:0] fetched_data;
    logic fetch_done;
    
    memory memory (
        .clk ( clk ),
        .rst ( rst ),
        
        .instruction_addr ( program_count ),
        .fetch_addr ( fetch_addr ),
        
        .bytes_to_write ( bytes_to_write ),
        .write_addr ( write_addr ),
        .write_data ( write_data ),
        .write_data_valid ( write_data_valid ),
        .write_done ( write_done ),
        
        .instruction_data ( instruction_data ),
        .instruction_fetch_done ( instruction_data_valid ), // todo: implement in memory handler
        
        .fetched_data ( fetched_data ),
        .fetch_done ( fetch_done )
    );
    
    logic [31:0] lhs;
    logic lhs_valid;
    
    logic [31:0] rhs;
    logic rhs_valid;
    
    logic [31:0] arithmetic_result;
    logic arithmetic_result_valid;
    
    arithmetic arithmetic (
        .clk ( clk ),
        .rst ( rst ),
        
        .lhs ( lhs ),
        .lhs_valid ( lhs_valid ),
        
        .rhs ( rhs ),
        .rhs_valid ( rhs_valid ),
        
        .operation ( funct_3 ),
        .operation_valid ( funct_3_valid ),
        
        .metadata ( funct_7 ),
        .metadata_valid ( funct_7_valid ),
        
        .result ( arithmetic_result ),
        .result_valid ( arithmetic_result_valid )
    );
    
    logic [31:0] working_address;
    assign working_address = register_result_1 + immediate_data; // for both load and store
    assign fetch_addr = working_address; // for now, until we need to worry about constantly fetching
    assign write_addr = working_address; // for now, until we need to worry about constantly writing 0 bytes
    
    assign lhs = register_result_1;
    assign lhs_valid = register_1_valid;
    
    assign rhs = immediate_arith ? immediate_data : register_result_2;
    assign rhs_valid = immediate_arith ? immediate_valid : register_2_valid;
    
    logic [31:0] load_data;
    always_comb unique case (funct_3)
        3'h0 : load_data = $signed(fetched_data[7:0]); // byte
        3'h1 : load_data = $signed(fetched_data[15:0]); // half
        3'h2 : load_data = fetched_data; // word
        3'h4 : load_data = $unsigned(fetched_data[7:0]); // unsigned byte
        3'h5 : load_data = $unsigned(fetched_data[15:0]); // unsigned half
        
        default : load_data = 'X;
    endcase
    
    always_comb unique case (funct_3)
        3'h0 : bytes_to_write = 3'h1; // byte
        3'h1 : bytes_to_write = 3'h2; // half
        3'h2 : bytes_to_write = 3'h4; // word
        
        default : bytes_to_write = 'X;
    endcase
    
    assign write_data = register_result_2;
    assign write_data_valid = store;
    
    logic execution_done;
    logic [31:0] next_instruction_addr;
    
    count count (
        .clk ( clk ),
        .rst ( rst ),
        
        .execution_done ( execution_done ),
        
        .lhs ( register_result_1 ),
        .lhs_valid ( register_1_valid ),
        
        .rhs ( register_result_2 ),
        .rhs_valid ( register_2_valid ),
        
        .operation ( funct_3 ),
        .operation_valid ( funct_3_valid ),
        
        .immediate_offset ( immediate_data ),
        .immediate_offset_valid ( immediate_valid ),
        
        .register_address ( register_result_1 ),
        .register_address_valid ( register_1_valid ),
        
        .branch ( branch ),
        .immediate_jump ( immediate_jump ),
        .register_jump ( register_jump ),
        
        .program_count ( program_count ),
        .next_instruction ( next_instruction_addr )
    );
    
    always_comb begin
        if (write_register_valid) begin
            execution_done = register_write_valid;
        end else if (store) begin
            execution_done = write_done;
        end else begin
            execution_done = opcode_valid;
        end // todo: ecall?
    end
    
    // create logic to figure out whether write data is valid by propagating
    always_comb begin
        if (register_arith || immediate_arith) begin
            write_register_data = arithmetic_result;
            write_register_data_valid = arithmetic_result_valid;
        end else if (load) begin
            write_register_data = load_data;
            write_register_data_valid = fetch_done;
        end else if (immediate_jump || register_jump) begin
            write_register_data = next_instruction_addr;
            write_register_data_valid = '1; // always true
        end else if (load_upper) begin
            write_register_data = immediate_data;
            write_register_data_valid = immediate_valid;
        end else if (load_upper_pc) begin
            write_register_data = program_count + immediate_data; // todo: use alu?
            write_register_data_valid = '1;
        end else begin
            write_register_data = 'X;
            write_register_data_valid = '0;
        end
    end

endmodule
