`include "./constants.v"


module Genie (
    input         clk,
    input         rst_n,
    output        wvalid,
    input         wready,
    output [25:0] waddr,
    output [31:0] wdata,
    output        rvalid,
    input         rready,
    output [25:0] raddr,
    input  [31:0] rdata,
    output [12:0] iaddr,
    input  [31:0] idata
);
    wire  [4:0] layer_type;
    wire  [4:0] act_type;
    wire        has_bias;

    wire        fc_rst;
    wire [11:0] fc_cin;
    wire [11:0] fc_cout;
    wire        fc_lif_start;
    wire        fc_lw_start;
    wire        fc_sof_start;
    wire        fc_done;

    wire        fc_dout_valid;
    wire        fc_dout_ready;
    wire [15:0] fc_dout_data;

    wire [26:0] base_addr;

    wire        wvalid_[0:3];
    wire        wready_[0:3];
    wire [25:0] waddr_[0:3];
    wire [31:0] wdata_[0:3];
    wire        rvalid_[0:3];
    wire        rready_[0:3];
    wire [25:0] raddr_[0:3];
    wire [31:0] rdata_[0:3];
    wire        is_fc;
    assign is_fc = layer_type == `LAYER_FC;

    assign wvalid = wvalid_[layer_type[1:0]];
    assign wready_[1] = wready & is_fc;
    assign waddr = waddr_[layer_type[1:0]];
    assign wdata = wdata_[layer_type[1:0]];
    assign rvalid = rvalid_[layer_type[1:0]];
    assign rready_[1] = rready & is_fc;
    assign raddr = raddr_[layer_type[1:0]];
    assign rdata_[1] = rdata & {32{is_fc}};

    FCDataLoader u_FCDataLoader (
        .clk(clk),
        .rst(fc_rst),

        .cin(fc_cin),
        .cout(fc_cout),
        .has_bias(has_bias),

        .lif_start(fc_lif_start),
        .lw_start(fc_lw_start),
        .sof_start(fc_sof_start),

        .fc_dout_valid(fc_dout_valid),
        .fc_dout_ready(fc_dout_ready),
        .fc_dout_data(fc_dout_data),

        .base_addr(base_addr),
        .wvalid(wvalid_[1]),
        .wready(wready_[1]),
        .waddr(waddr_[1]),
        .wdata(wdata_[1]),
        .rvalid(rvalid_[1]),
        .rready(rready_[1]),
        .raddr(raddr_[1]),
        .rdata(rdata_[1]),

        .done(fc_done)
    );

    FCCore u_FCCore (
        .clk(clk),
        .rst(fc_rst),
        .cin(fc_cin),
        .cout(fc_cout),
        .has_bias(has_bias),
        .din_valid(rready),
        .din_data(rdata[15:0]),
        .dout_valid(fc_dout_valid),
        .dout_ready(fc_dout_ready),
        .dout_data(fc_dout_data)
    );

    Decoder u_Decoder (
        .clk(clk),
        .rst_n(rst_n),
        .iaddr(iaddr),
        .idata(idata),
        
        .layer_type(layer_type),
        .act_type(act_type),
        .has_bias(has_bias),

        .fc_rst(fc_rst),
        .fc_cin(fc_cin),
        .fc_cout(fc_cout),
        .fc_lif_start(fc_lif_start),
        .fc_lw_start(fc_lw_start),
        .fc_sof_start(fc_sof_start),
        .fc_next_partition(1'b0),
        .fc_done(fc_done),

        .base_addr(base_addr)
    );
endmodule
