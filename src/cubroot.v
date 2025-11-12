module cubroot (
    input clk_i,
    input rst_i,

    input [7:0] x_bi,
    input start_i,

    output busy_o,
    output reg [7:0] y_bo
);

    // FSM states
    localparam IDLE = 4'd0;
    localparam S1 = 4'd1;
    localparam S2 = 4'd2;
    localparam S3 = 4'd3;
    localparam S4 = 4'd4;
    localparam S5 = 4'd5;
    localparam S6 = 4'd6;
    localparam S7 = 4'd7;
    localparam NEXT_ITER = 4'd8;

    reg [3:0] state;
    reg [7:0] x;
    reg [7:0] y;
    reg [2:0] s; // (9-0)
    reg [7:0] b; // hope it will not overlflow
    assign busy_o = (state != IDLE);
    wire start_mul;
    assign start_mul = (state == S2);
    wire busy_mul;
    wire [15:0] mul_res;
    mult mul (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .a_bi(y),       
        .b_bi(b), 
        .start_i(start_mul),
        .busy_o(busy_mul),
        .y_bo(mul_res)       
    );
    // Main sequential logic with improved structure
    always @(posedge clk_i) begin
        if (rst_i) begin
            // Reset all registers to initial state
            state <= IDLE;
            x <= 8'd0;
            y <= 8'd0;
            s <= 3'd6;
            y_bo <= 8'd0;
            b <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (start_i) begin
                        // Initialize for square root calculation
                        state <= S1;
                        x <= x_bi;
                        y <= 8'd0;
                        s <= 3'd6;
                        b <= 8'd0;
                    end
                end
                
                S1: begin
                    y <= (y << 1); // y * 2
                    b <= ((y << 1) + 1);
                    state <= S2;
                end
                S2: begin
                    // do nothing, b * y mul started
                    state <= S3;
                end
                S3: begin
                    if (!busy_mul) begin
                        state <= S4;
                        b <= mul_res + (mul_res << 1); // * 3
                    end
                end
                S4: begin
                    state <= S5;
                    b <= ((b + 1) << s);
                end
                S5: begin
                    if (x >= b)begin
                        state <= S6;
                    end else begin
                        state <= NEXT_ITER;
                    end
                end
                S6: begin
                    x <= x - b;
                    state <= S7;
                end
                
                S7: begin
                    y <= y+1;
                    state <= NEXT_ITER;
                end
                NEXT_ITER: begin
                    if (s == 0) begin
                        y_bo <= y;
                        state <= IDLE;
                    end else begin
                        s <= s - 3;
                        state <= S1;
                    end
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule