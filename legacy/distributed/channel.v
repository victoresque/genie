module Channel (
    clk,
    rst_n,
    data_in,
    data_out
);
    parameter DWIDTH = 32;
    parameter DELAY = 64;

    input               clk;
    input               rst_n;
    input  [DWIDTH-1:0] data_in;
    output [DWIDTH-1:0] data_out;

    reg  [DWIDTH-1:0] fifo [0:DELAY-1];

    assign data_out = fifo[DELAY-1];

    integer i;

    always @ (posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (i = 0; i < DELAY; i = i+1) fifo[i] <= {DWIDTH{1'b0}};
        end
        else begin
            fifo[0] <= data_in;
            for (i = 1; i < DELAY; i = i+1) fifo[i] <= fifo[i-1];
        end
    end
endmodule
