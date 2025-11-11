`include "src/cubroot.v"
`include "src/multiply.v"
module cubroot_add_system (
    input clk_i,
    input rst_i,
    input start_i,
    input [7:0] a_bi,
    input [7:0] b_bi,
    output [15:0] result,
    output done
);

    wire sqrt_busy, mult_busy;
    wire sqrt_start, mult_start;
    wire [7:0] sqrt_result;
    
    localparam [1:0] 
        IDLE = 2'b00,
        CALC_SQRT = 2'b01,
        CALC_MULT = 2'b10,
        DONE_STATE = 2'b11;
    
    reg [1:0] state;
    
    assign sqrt_start = (state == IDLE) && start_i;
    assign mult_start = (state == CALC_SQRT) && !sqrt_busy;
    assign done = (state == DONE_STATE);
    
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (start_i) begin
                        state <= CALC_SQRT;
                    end
                end
                
                CALC_SQRT: begin
                    if (!sqrt_busy) begin
                        state <= CALC_MULT;
                    end
                end
                
                CALC_MULT: begin
                    if (!mult_busy) begin
                        state <= DONE_STATE;
                    end
                end
                
                DONE_STATE: begin
                    state <= IDLE;
                end
            endcase
        end
    end
    
    cubroot sqrt_inst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .x_bi(b_bi),       
        .start_i(sqrt_start),
        .busy_o(sqrt_busy),
        .y_bo(sqrt_result)
    );
    
    mult mult_inst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .a_bi(a_bi),       
        .b_bi(sqrt_result), 
        .start_i(mult_start),
        .busy_o(mult_busy),
        .y_bo(result)       
    );

endmodule