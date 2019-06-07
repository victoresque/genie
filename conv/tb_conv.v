`timescale 1ns/10ps
`define CYCLE       10.0
`define HCYCLE      (`CYCLE/2)
`define MAX_CYCLE   1000000
`define RST_DELAY   (5.5*`CYCLE)


module tb;
    wire               clk;
    wire               rst_n;

    initial begin
        $dumpfile("tb.vcd");
        $dumpvars;
        // $fsdbDumpfile("tb.fsdb");
        // $fsdbDumpvars;
    end

    wire        wvalid;
    wire        wready;
    wire [25:0] waddr;
    wire [31:0] wdata;
    wire        rvalid;
    wire        rready;
    wire [25:0] raddr;
    wire [31:0] rdata;

    reg  [31:0] a[0:32767];
    reg  [31:0] b[0:32767];
    parameter H = 12;
    parameter W = 12;
    parameter I = 12;
    parameter O = 12;
    parameter K = 3;

    integer h, w, i, o, ki, kj;
    integer addr;

    reg         din_valid;
    reg  [15:0] din_data;

    BehavConvCore u_BehavConvCore (
        .clk(clk),
        .rst_n(rst_n),
        .Hp(5'b0),
        .Wp(5'b0),
        .I(8'b0),
        .O(8'b0),
        .K(3'b0),
        .din_valid(din_valid),
        .din_data(din_data),
        .dout_valid(),
        .dout_ready(1'b0),
        .dout_data()
    );

    initial begin
        $readmemh("./mem/a.mem", a, 0, 32767);
        $readmemh("./mem/b.mem", b, 0, 32767);
    end

    initial begin
        din_valid = 0;
        # (`CYCLE * 50);

        for (i = 0; i < I; i = i + 1) begin
            for (h = 0; h < H; h = h + 1) begin
                for (w = 0; w < W; w = w + 1) begin
                    addr = i * H * W + h * W + w;
                    # (`CYCLE * 5);
                    din_valid = 1'b1;
                    din_data = a[addr][15:0];
                    #(`CYCLE);
                    din_valid = 1'b0;
                end 
            end
        end

        for (o = 0; o < O; o = o + 1) begin
            for (i = 0; i < I; i = i + 1) begin
                for (ki = 0; ki < K; ki = ki + 1) begin
                    for (kj = 0; kj < K; kj = kj + 1) begin
                        addr = o * I * K * K + i * K * K + ki * K + kj;
                        # (`CYCLE * 5);
                        din_valid = 1'b1;
                        din_data = b[addr][15:0];
                        #(`CYCLE);
                        din_valid = 1'b0;
                    end 
                end
            end
        end

        din_valid = 1;
        # (`CYCLE);
        din_valid = 0;

    end

    Clkgen clk0 (
        .clk(clk),
        .rst_n(rst_n)
    );
endmodule


module Clkgen (
    output reg clk,
    output reg rst_n
);
    always # (`HCYCLE) clk = ~clk;

    initial begin
        clk = 1'b1;
        rst_n = 1; # (             0.25 * `CYCLE);
        rst_n = 0; # (`RST_DELAY - 0.25 * `CYCLE);
        rst_n = 1; # (       `MAX_CYCLE * `CYCLE);
        $finish;
    end
endmodule
