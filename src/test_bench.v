`timescale 1ns/1ps
`include "src/cubroot_add_system.v"

module test_bench;
    reg clk = 0;
    reg rst_i = 1;
    reg start_i = 0;
    reg [7:0] a_bi = 0;
    reg [7:0] b_bi = 0;
    wire [15:0] result;
    wire done;

    cubroot_add_system DUT (
        .clk_i(clk),
        .rst_i(rst_i),
        .start_i(start_i),
        .a_bi(a_bi),
        .b_bi(b_bi),
        .result(result),
        .done(done)
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

        test(8'd4,   8'd16,  16'd16,  1);   // 4 * sqrt(16) = 16
        test(8'd5,   8'd25,  16'd25,  2);   // 5 * sqrt(25) = 25
        test(8'd3,   8'd2,   16'd3,   3);   // 3 * sqrt(2) = 3
        test(8'd0,   8'd100, 16'd0,   4);   // 0 * sqrt(100) = 0
        test(8'd8,   8'd0,   16'd0,   5);   // 8 * sqrt(0) = 0
        test(8'd1,   8'd1,   16'd1,   6);   // 1 * sqrt(1) = 1
        test(8'd255, 8'd255, 16'd3825,7);   // 255 * sqrt(255) ≈ 3825
        test(8'd100, 8'd4,   16'd200, 8);   // 100 * sqrt(4) = 200
        test(8'd2,   8'd225, 16'd30,  9);   // 2 * sqrt(225) = 30
        test(8'd6,   8'd64,  16'd48,  10);  // 6 * sqrt(64) = 48

        // Print statistics
        print_statistics();

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
            
            @(posedge clk) start_i = 1;
            @(posedge clk) start_i = 0;

            // Count cycles in each state
            sqrt_cycles = 0;
            mult_cycles = 0;
            overhead_cycles = 0;
            total_cycles = 0;
            
            while (!done && total_cycles < MAX_WAIT_CYCLES) begin
                @(posedge clk);
                total_cycles = total_cycles + 1;
                
                // Count cycles for each phase based on FSM state
                case (DUT.state)
                    2'b01: sqrt_cycles = sqrt_cycles + 1;  // CALC_SQRT
                    2'b10: mult_cycles = mult_cycles + 1;  // CALC_MULT
                    default: overhead_cycles = overhead_cycles + 1;
                endcase
            end

            // Calculate timing in nanoseconds
            sqrt_time_ns = sqrt_cycles * CLK_PERIOD;
            mult_time_ns = mult_cycles * CLK_PERIOD;
            total_time_ns = total_cycles * CLK_PERIOD;

            // Update statistics
            if (done) begin
                test_count = test_count + 1;
                total_sqrt_cycles = total_sqrt_cycles + sqrt_cycles;
                total_mult_cycles = total_mult_cycles + mult_cycles;
                total_system_cycles = total_system_cycles + total_cycles;
                
                if (sqrt_cycles < min_sqrt_cycles) min_sqrt_cycles = sqrt_cycles;
                if (sqrt_cycles > max_sqrt_cycles) max_sqrt_cycles = sqrt_cycles;
                if (mult_cycles < min_mult_cycles) min_mult_cycles = mult_cycles;
                if (mult_cycles > max_mult_cycles) max_mult_cycles = mult_cycles;
                
                $display("Test %2d: %3d × √%-3d = %-5d (exp %-5d) | SQRT: %2d cyc (%5.1f ns) | MULT: %2d cyc (%4.1f ns) | TOTAL: %2d cyc (%5.1f ns)", 
                         num, a, b, result, expected, 
                         sqrt_cycles, sqrt_time_ns,
                         mult_cycles, mult_time_ns,
                         total_cycles, total_time_ns);
            end else begin
                $display("TIMEOUT in test %0d", num);
            end

            repeat (2) @(posedge clk);
        end
    endtask
    
    task print_statistics;
        real avg_sqrt_cycles, avg_mult_cycles, avg_total_cycles;
        real avg_sqrt_time, avg_mult_time, avg_total_time;
        begin
            avg_sqrt_cycles = total_sqrt_cycles / test_count;
            avg_mult_cycles = total_mult_cycles / test_count;
            avg_total_cycles = total_system_cycles / test_count;
            
            avg_sqrt_time = avg_sqrt_cycles * CLK_PERIOD;
            avg_mult_time = avg_mult_cycles * CLK_PERIOD;
            avg_total_time = avg_total_cycles * CLK_PERIOD;
            
            $display("\n========================================");
            $display("           TIMING STATISTICS");
            $display("========================================");
            $display("Total tests run: %0d", test_count);
            $display("");
            $display("SQRT MODULE:");
            $display("  Average: %0.2f cycles (%0.2f ns)", avg_sqrt_cycles, avg_sqrt_time);
            $display("  Min:     %0d cycles (%0.1f ns)", min_sqrt_cycles, min_sqrt_cycles * CLK_PERIOD);
            $display("  Max:     %0d cycles (%0.1f ns)", max_sqrt_cycles, max_sqrt_cycles * CLK_PERIOD);
            $display("");
            $display("MULT MODULE:");
            $display("  Average: %0.2f cycles (%0.2f ns)", avg_mult_cycles, avg_mult_time);
            $display("  Min:     %0d cycles (%0.1f ns)", min_mult_cycles, min_mult_cycles * CLK_PERIOD);
            $display("  Max:     %0d cycles (%0.1f ns)", max_mult_cycles, max_mult_cycles * CLK_PERIOD);
            $display("");
            $display("TOTAL SYSTEM:");
            $display("  Average: %0.2f cycles (%0.2f ns)", avg_total_cycles, avg_total_time);
            $display("  Total time for all tests: %0.2f ns", total_system_cycles * CLK_PERIOD);
            $display("========================================\n");
        end
    endtask

endmodule