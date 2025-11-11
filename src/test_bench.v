`timescale 1ns/1ps
`include "src/cubroot_add_system.v"

module test_bench;
    reg clk = 0;
    reg rst_i = 1;
    reg start_i = 0;
    reg [7:0] a_bi = 0;
    reg [7:0] b_bi = 0;
    wire [15:0] result;
    wire busy;

    cubroot_add_system DUT (
        .clk_i(clk),
        .rst_i(rst_i),
        .start_i(start_i),
        .a_bi(a_bi),
        .b_bi(b_bi),
        .result(result),
        .busy_o(busy)
    );

    // Clock period = 10ns (100 MHz)
    always #5 clk = ~clk;
    
    // Statistics counters
    integer total_sqrt_cycles = 0;
    integer total_mult_cycles = 0;
    integer total_system_cycles = 0;
    integer test_count = 0;
    integer min_sqrt_cycles = 9999;
    integer max_sqrt_cycles = 0;
    integer min_mult_cycles = 9999;
    integer max_mult_cycles = 0;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, test_bench);

        $display("\n========================================");
        $display("   CUBROOT-ADD SYSTEM TIMING ANALYSIS");
        $display("   Clock Frequency: 100 MHz (10 ns period)");
        $display("========================================\n");

        rst_i = 1;
        repeat (2) @(posedge clk);
        rst_i = 0;
        @(posedge clk);

        test(8'd4,   8'd16,  16'd20,  1);   // 4^2 + sqrt(16) = 20
        test(8'd5,   8'd25,  16'd30,  2);   // 5^2 + sqrt(25) = 30
        test(8'd3,   8'd2,   16'd10,   3);   // 3^2 + sqrt(2) = 10
        test(8'd0,   8'd100, 16'd10,   4);   // 0^2 + sqrt(100) = 10
        test(8'd8,   8'd0,   16'd64,   5);   // 8^2 + sqrt(0) = 64
        test(8'd1,   8'd1,   16'd2,   6);   // 1^2 + sqrt(1) = 2
        test(8'd255, 8'd255, 16'd65040,7);   // 255^2 + sqrt(255) = 65040
        test(8'd100, 8'd4,   16'd10002, 8);   // 100^2 + sqrt(4) = 10002
        test(8'd2,   8'd225, 16'd19,  9);   // 2^2 + sqrt(225) = 19
        test(8'd6,   8'd64,  16'd44,  10);  // 6^2 + sqrt(64) = 44


        #10 $finish;
    end

    localparam integer MAX_WAIT_CYCLES = 2000;
    localparam real CLK_PERIOD = 10.0; // 100 MHz = 10 ns period

    task test;
        input [7:0] a, b;
        input [15:0] expected;
        input integer num;
        integer sqrt_cycles, mult_cycles, total_cycles, overhead_cycles;
        real sqrt_time_ns, mult_time_ns, total_time_ns;
        begin
            a_bi = a;
            b_bi = b;
            
            start_i = 1;
            @(posedge clk);
            start_i = 0;

            // Count cycles in each state
            sqrt_cycles = 0;
            mult_cycles = 0;
            overhead_cycles = 0;
            total_cycles = 0;
            @(posedge clk);
            
            while (busy && total_cycles < MAX_WAIT_CYCLES) begin
                @(posedge clk);
                total_cycles = total_cycles + 1;
            end

            total_time_ns = total_cycles * CLK_PERIOD;

            // Update statistics
            if (!busy) begin
                test_count = test_count + 1;
                
                
                $display("Test %2d: %3d + √%-3d = %-5d (exp %-5d) | TIME: %2d cyc (%5.1f ns)", 
                         num, a, b, result, expected, 
                         total_cycles, total_time_ns);
            end else begin
                $display("TIMEOUT in test %0d", num);
            end

            repeat (2) @(posedge clk);
        end
    endtask
    

endmodule