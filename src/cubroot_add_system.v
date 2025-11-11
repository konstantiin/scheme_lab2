`include "src/cubroot.v"
`include "src/multiply.v"
module cubroot_add_system (
    input clk_i,
    input rst_i,
    input start_i,
    input [7:0] a_bi,
    input [7:0] b_bi,
    output busy_o,
    output reg [15:0] result
);

    wire cub_busy, square_busy;
    wire square_start, cub_start;
    wire [7:0] cub_result;
    wire [15:0] square_result;
    
    localparam
        IDLE = 1'b0,
        WORKING = 1'b1;
    
    reg state;
    
    assign square_start = (state == IDLE) && start_i;
    assign cub_start = square_start;
    assign busy_o = state;
    
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (start_i) begin
                        state <= WORKING;
                    end
                end
                
                WORKING: begin
                    if (!square_busy && !cub_busy) begin
                        state <= IDLE;
                        result <= square_result + cub_result;
                    end
                end
                
            endcase
        end
    end
    
    cubroot cub (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .x_bi(b_bi),       
        .start_i(cub_start),
        .busy_o(cub_busy),
        .y_bo(cub_result)
    );
    
    mult square (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .a_bi(a_bi),       
        .b_bi(a_bi), 
        .start_i(square_start),
        .busy_o(square_busy),
        .y_bo(square_result)       
    );

endmodule