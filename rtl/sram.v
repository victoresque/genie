module ext_sram(
    input         W0_clk,
    input  [25:0] W0_addr,
    input  [31:0] W0_data,
    input         W0_valid,
    output        W0_ready,
    input         R0_clk,
    input  [25:0] R0_addr,
    output [31:0] R0_data,
    input         R0_valid,
    output        R0_ready
);
    reg        W0_ready_r;
    reg        R0_ready_r;
    reg [25:0] R0_addr_r;
    reg [31:0] ram [67108863:0];
    
    assign R0_data = ram[R0_addr_r];
    assign W0_ready = W0_ready_r;
    assign R0_ready = R0_ready_r;

    parameter RD_LATENCY = 2;
    parameter WR_LATENCY = 2;
    integer rdcnt;
    integer wrcnt;

    initial begin
        rdcnt = 0;
        wrcnt = 0;
    end
    
    always @ (posedge R0_clk) begin
        if (R0_valid && (rdcnt < RD_LATENCY)) begin
            rdcnt <= rdcnt + 1;
        end
        else if (R0_valid) begin
            if(R0_ready_r) rdcnt <= 0;
            R0_ready_r <= 1 & ~R0_ready_r;
            R0_addr_r <= R0_addr;
        end
        else begin
            R0_ready_r <= 0;
        end
    end

    always @ (posedge W0_clk) begin
        if (W0_valid && (wrcnt < WR_LATENCY)) begin
            wrcnt <= wrcnt + 1;
        end
        else if (W0_valid) begin
            if(W0_ready_r) wrcnt <= 0;
            W0_ready_r <= 1 & ~W0_ready_r;
            ram[W0_addr] <= W0_data;
        end
        else begin
            W0_ready_r <= 0;
        end
    end
endmodule


module ext_insn_rom(
    input         clk,
    input  [12:0] raddr,
    output [31:0] rdata
);
    reg [31:0] ram [8191:0];  
    assign rdata = ram[raddr];
endmodule


module sram4K (
    input         clk,
    input   [9:0] addr,
    input         wen,
    input  [31:0] wdata,
    output [31:0] rdata
);
    reg [31:0] ram [1023:0];
    
    assign rdata = ram[addr];

    always @ (posedge clk)
        if (wen) ram[addr] <= wdata;
endmodule
