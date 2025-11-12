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
    integer test_count = 0;

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

        test(8'd0,   8'd27,  16'd3,  1);   // 0^2 + cubr(27) = 3
        test(8'd0,   8'd26,  16'd2,  2);   // 0^2 + cubr(26) = 2
        test(8'd0,   8'd9,  16'd2,  3);   // 0^2 + cubr(9) = 2
        test(8'd0,   8'd8,  16'd2,  4);   // 0^2 + cubr(8) = 2
        test(8'd0,   8'd7,  16'd1,  5);   // 0^2 + cubr(7) = 1
        test(8'd0,   8'd1,  16'd1,  6);   // 0^2 + cubr(1) = 1
        test(8'd0,   8'd255,  16'd6,  7);   // 0^2 + cubr(1) = 1
        test(8'd4,   8'd16,  16'd18,  8);   // 4^2 + sqrt(16) = 18
        test(8'd5,   8'd25,  16'd27,  9);   // 5^2 + sqrt(25) = 27
        test(8'd3,   8'd2,   16'd10,   10);   // 3^2 + sqrt(2) = 10
        test(8'd8,   8'd0,   16'd64,   11);   // 8^2 + sqrt(0) = 64
        test(8'd1,   8'd1,   16'd2,   12);   // 1^2 + sqrt(1) = 2
        test(8'd255, 8'd255, 16'd65031, 13);   // 255^2 + sqrt(255) = 650310
        test(8'd100, 8'd10,   16'd10002, 14);   // 100^2 + sqrt(4) = 10002


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
                
                
                $display("Test %2d: %3d^2 + cubroot(%-3d) = %-5d (exp %-5d) | TIME: %2d cyc (%5.1f ns)", 
                         num, a, b, result, expected, 
                         total_cycles, total_time_ns);
            end else begin
                $display("TIMEOUT in test %0d", num);
            end

            repeat (2) @(posedge clk);
        end
    endtask
    

endmodule