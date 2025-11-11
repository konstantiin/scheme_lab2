module cubroot (
    input clk_i,
    input rst_i,

    input [7:0] x_bi,
    input start_i,

    output busy_o,
    output reg [7:0] y_bo
);

    // FSM states
    localparam IDLE = 1'b0;
    localparam WORK = 1'b1;

    // Internal state and registers
    reg state;
    reg [7:0] x;        // Current working value
    reg [7:0] y;        // Result accumulator
    reg [7:0] m;        // Bit mask
    reg [7:0] b_temp;   // Temporary for b = y | m
    reg [7:0] y_temp;   // Temporary for y_shifted
    
    // Combinational signals for cleaner code
    wire [7:0] m_shifted;
    wire m_not_zero;
    
    // Combinational logic
    assign m_shifted = m >> 2;
    assign m_not_zero = (m != 8'd0);
    assign busy_o = state;

    // Main sequential logic with improved structure
    always @(posedge clk_i) begin
        if (rst_i) begin
            // Reset all registers to initial state
            state <= IDLE;
            x <= 8'd0;
            y <= 8'd0;
            m <= 8'd0;
            y_bo <= 8'd0;
            b_temp <= 8'd0;
            y_temp <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (start_i) begin
                        // Initialize for square root calculation
                        state <= WORK;
                        x <= x_bi;
                        y <= 8'd0;
                        m <= 8'b01000000;   // Initial mask: 1 << (WIDTH-2)
                        y_bo <= 8'd0;
                    end
                end
                
                WORK: begin
                    if (m_not_zero) begin
                        // Calculate temporary values using blocking for immediate computation
                        b_temp = y | m;
                        y_temp = y >> 1;
                        
                        // Conditionally update based on comparison
                        if (x >= b_temp) begin
                            // If x >= b_temp, subtract and set bit in result
                            x <= x - b_temp;
                            y <= y_temp | m;
                        end else begin
                            // Only update y with shifted value
                            y <= y_temp;
                        end
                        
                        // Shift mask for next iteration
                        m <= m_shifted;
                    end else begin
                        // Computation complete, output final result
                        state <= IDLE;
                        y_bo <= y;
                    end
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule