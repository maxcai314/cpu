`timescale 1ns / 1ps

module cpu_test(

);

    logic clk;
    logic rst;
    
    five_cycle_cpu cpu (
        .clk ( clk ),
        .rst ( rst )
    );
    
    initial forever begin
        clk = '1;
        #5;
        clk = '0;
        #5;
    end
    
    initial begin
        #15;
        
        // reset
        @(posedge clk)
        rst = '1;
        @(posedge clk)
        $readmemh("load_store_arith.mem", cpu.memory.data);
        @(posedge clk)
        rst = '0;
        @(posedge clk)
        
        #15;
    end

endmodule
