`timescale 1ns/10ps
`define CYCLE       10.0
`define HCYCLE      (`CYCLE/2)
`define END_CYCLE   1000
`define RST_DELAY   (2.5*`CYCLE)


module tb;
    wire               clk;
    wire               rst_n;

    initial begin
        $dumpfile("tb.vcd");
        $dumpvars;
    end

    Clkgen clk0 (
        .clk(clk),
        .rst_n(rst_n)
    );

    Topology #(
        .S(3),
        .W(3)
    ) u_topology (
        .clk(clk),
        .rst_n(rst_n)
    );
endmodule


module Server (
    clk,
    rst_n,
    S_rdata,
    S_wdata,
    W_id,
    W_read,
    W_rready,
    W_rdata,
    W_write,
    W_wready,
    W_wdata
);
    parameter W = 3;
    parameter IDWIDTH = $clog2(W);

    input                clk;
    input                rst_n;
    input         [31:0] S_rdata;
    output        [31:0] S_wdata;
    output [IDWIDTH-1:0] W_id;
    output               W_read;
    input                W_rready;
    input         [31:0] W_rdata;
    output               W_write;
    input                W_wready;
    output        [31:0] W_wdata;
endmodule


module Worker (
    id,
    read,
    rready,
    rdata,
    write,
    wready,
    wdata
);
    parameter ID = 0;

    input   [2:0] id;
    input         read;
    output        rready;
    output [31:0] rdata;
    input         write;
    output        wready;
    input  [31:0] wdata;
endmodule


module Topology (
    clk,
    rst_n
);
    parameter S = 3;
    parameter W = 3;

    input clk;
    input rst_n;

    genvar i, j;
    generate
        for (i = 0; i < S; i = i+1) begin : gen_server
            wire [31:0] S_rdata;
            wire [31:0] S_wdata_channel_in;
            wire [31:0] S_wdata_channel_out;
            wire  [2:0] W_id;
            wire        W_read;
            wire        W_rready;
            wire [31:0] W_rdata;
            wire        W_write;
            wire        W_wready;
            wire [31:0] W_wdata;

            Server # (
                .W(W)
            ) server (
                .clk(clk),
                .rst_n(rst_n),
                .S_rdata(S_rdata),
                .S_wdata(S_wdata_channel_in),
                .W_id(W_id),
                .W_read(W_read),
                .W_rready(W_rready),
                .W_rdata(W_rdata),
                .W_write(W_write),
                .W_wready(W_wready),
                .W_wdata(W_wdata)
            );

            for (j = 0; j < W; j = j+1) begin : gen_worker
                Worker # (
                    .ID(j + 1)
                ) worker (
                    .id(W_id),
                    .read(W_read),
                    .rready(W_rready),
                    .rdata(W_rdata),
                    .write(W_write),
                    .wready(W_wready),
                    .wdata(W_wdata)
                );
            end

            Channel # (
                .DWIDTH(32),
                .DELAY(100)
            ) channel (
                .clk(clk),
                .rst_n(rst_n),
                .data_in(S_wdata_channel_in),
                .data_out(S_wdata_channel_out)
            );
        end

        assign gen_server[0].S_rdata = gen_server[S-1].S_wdata_channel_out;
        for (i = 1; i < S; i = i+1) begin
            assign gen_server[i].S_rdata = gen_server[i-1].S_wdata_channel_out;
        end
    endgenerate
endmodule


module Clkgen (
    clk,
    rst_n
);
    output reg clk;
    output reg rst_n;

    always # (`HCYCLE) clk = ~clk;

    initial begin
        clk = 1'b1;

        rst_n = 1; # (             0.25 * `CYCLE);
        rst_n = 0; # (`RST_DELAY - 0.25 * `CYCLE);
        rst_n = 1; # (       `END_CYCLE * `CYCLE);

        $finish;
    end
endmodule
