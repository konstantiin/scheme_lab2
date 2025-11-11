module mult (input clk_i,
             input rst_i,
             input [7:0] a_bi,
             input [7:0] b_bi,
             input start_i,
             output busy_o,
             output reg [15:0] y_bo);
    
    // FSM states
    localparam IDLE = 1'b0;
    localparam WORK = 1'b1;
    
    // Internal registers and wires
    reg [3:0] ctr;          // Extended counter width
    wire end_step;
    wire early_exit;        // Early termination optimization
    wire [7:0] part_sum;
    wire [15:0] shifted_part_sum;
    reg [7:0] a, b;
    reg [15:0] part_res;
    reg state;
    
    // Combinational logic
    assign part_sum         = a & {8{b[ctr]}};
    assign shifted_part_sum = part_sum << ctr;
    assign end_step         = (ctr == 4'd7);
    assign early_exit       = (b == 8'd0);  // Optimization: skip if b is zero
    assign busy_o           = state;
    

    // Main sequential logic
    always @(posedge clk_i) begin
        if (rst_i) begin
            // Reset all registers
            ctr      <= 4'd0;
            part_res <= 16'd0;
            y_bo     <= 16'd0;
            a        <= 8'd0;
            b        <= 8'd0;
            state    <= IDLE;
        end 
        else begin
            case (state)
                IDLE: begin
                    if (start_i) begin
                        state <= WORK;
                        // Load input values
                        a        <= a_bi;
                        b        <= b_bi;
                        ctr      <= 4'd0;
                        part_res <= 16'd0;
                    end
                end
                
                WORK: begin
                    // Check for completion or early exit
                    if (end_step || early_exit) begin
                        state <= IDLE;
                        y_bo  <= part_res + shifted_part_sum;
                    end else begin
                        // Accumulate partial result
                        part_res <= part_res + shifted_part_sum;
                        ctr      <= ctr + 4'd1;
                        end
                    end
                    
                default: begin
                        state <= IDLE;
                    end
            endcase
        end
    end
endmodule
