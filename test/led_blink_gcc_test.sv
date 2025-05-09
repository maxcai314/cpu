`timescale 1ns / 1ps

module led_blink_gcc_test(

);

    logic clk;
    logic rst;
    
    five_cycle_cpu cpu (
        .clk ( clk ),
        .rst ( rst )
    );
    
    initial forever begin
        clk = '1;
        #10;
        clk = '0;
        #10;
    end
    
    initial begin
        #30;
        
        // reset
        @(posedge clk)
        rst = '1;
        @(posedge clk)
        $readmemh("test_led_blink_gcc.mem", cpu.memory.data);
        @(posedge clk)
        rst = '0;
        @(posedge clk)
        
        #15;
    end

endmodule
