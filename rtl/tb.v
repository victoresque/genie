`timescale 1ns/10ps
`define CYCLE       10.0
`define HCYCLE      (`CYCLE/2)
`define MAX_CYCLE   10000000
`define RST_DELAY   (5.5*`CYCLE)


module tb;
    wire               clk;
    wire               rst_n;

    initial begin
        // $dumpfile("tb.vcd");
        // $dumpvars;
        $fsdbDumpfile("tb.fsdb");
        $fsdbDumpvars;
    end

    wire        wvalid;
    wire        wready;
    wire [25:0] waddr;
    wire [31:0] wdata;
    wire        rvalid;
    wire        rready;
    wire [25:0] raddr;
    wire [31:0] rdata;

    ext_sram u_ext_sram (
        .W0_clk(clk),
        .W0_addr(waddr),
        .W0_valid(wvalid),
        .W0_ready(wready),
        .W0_data(wdata),
        .R0_clk(clk),
        .R0_addr(raddr),
        .R0_valid(rvalid),
        .R0_ready(rready),
        .R0_data(rdata)
    );

    wire [12:0] iaddr;
    wire [31:0] idata;
    ext_insn_rom u_insn_rom (
        .clk(clk),
        .raddr(iaddr),
        .rdata(idata)
    );

    initial begin
        $readmemh("../mem/model.mem", u_ext_sram.ram, 0, 67108863);
        $readmemh("../mem/din.mem", u_ext_sram.ram, 0, 67108863);
        $readmemb("../mem/insn.mem", u_insn_rom.ram, 0, 8191);
    end

    Genie u_Genie (
        .clk(clk),
        .rst_n(rst_n),
        .wvalid(wvalid),
        .wready(wready),
        .waddr(waddr),
        .wdata(wdata),
        .rvalid(rvalid),
        .rready(rready),
        .raddr(raddr),
        .rdata(rdata),
        .iaddr(iaddr),
        .idata(idata)
    );

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
