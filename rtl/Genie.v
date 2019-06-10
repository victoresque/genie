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

    wire        is_fc;
    wire        is_cv;
    wire        is_mp;
    assign is_fc = layer_type == `LAYER_FC;
    assign is_cv = layer_type == `LAYER_CV;
    assign is_mp = layer_type == `LAYER_MP;

    wire        wvalid_[0:3];
    wire        wready_[0:3];
    wire [25:0] waddr_[0:3];
    wire [31:0] wdata_[0:3];
    wire        rvalid_[0:3];
    wire        rready_[0:3];
    wire [25:0] raddr_[0:3];
    wire [31:0] rdata_[0:3];

    assign wvalid = wvalid_[layer_type[1:0]];
    assign wready_[`LAYER_FC] = wready & is_fc;
    assign wready_[`LAYER_CV] = wready & is_cv;
    assign wready_[`LAYER_MP] = wready & is_mp;
    assign waddr = waddr_[layer_type[1:0]];
    assign wdata = wdata_[layer_type[1:0]];
    assign rvalid = rvalid_[layer_type[1:0]];
    assign rready_[`LAYER_FC] = rready & is_fc;
    assign rready_[`LAYER_CV] = rready & is_cv;
    assign rready_[`LAYER_MP] = rready & is_mp;
    assign raddr = raddr_[layer_type[1:0]];
    assign rdata_[`LAYER_FC] = rdata & {32{is_fc}};
    assign rdata_[`LAYER_CV] = rdata & {32{is_cv}};
    assign rdata_[`LAYER_MP] = rdata & {32{is_mp}};

    wire        fc_rst;
    wire [11:0] fc_cin;
    wire [11:0] fc_cout;
    wire        fc_lif_start;
    wire        fc_lw_start;
    wire        fc_sof_start;
    wire        fc_done;
    wire [26:0] fc_base_addr;

    FCDataLoader u_FCDataLoader (
        .clk(clk),
        .rst(fc_rst),

        .cin(fc_cin),
        .cout(fc_cout),
        .has_bias(has_bias),
        .act_type(act_type),

        .lif_start(fc_lif_start),
        .lw_start(fc_lw_start),
        .sof_start(fc_sof_start),

        .base_addr(fc_base_addr),
        .wvalid(wvalid_[`LAYER_FC]),
        .wready(wready_[`LAYER_FC]),
        .waddr(waddr_[`LAYER_FC]),
        .wdata(wdata_[`LAYER_FC]),
        .rvalid(rvalid_[`LAYER_FC]),
        .rready(rready_[`LAYER_FC]),
        .raddr(raddr_[`LAYER_FC]),
        .rdata(rdata_[`LAYER_FC]),

        .done(fc_done)
    );

    wire        cv_rst;
    wire [10:0] cv_I;
    wire [10:0] cv_O;
    wire  [4:0] cv_K;
    wire [12:0] cv_H;     // TODO: bit width change to 13
    wire [12:0] cv_W;     // TODO: bit width change to 13
    wire [26:0] cv_ifaddr;
    wire [26:0] cv_weaddr;
    wire [26:0] cv_ofaddr;
    wire        cv_load_weight;
    wire        cv_load_input;
    wire        cv_store_output;
    wire        cv_done;

    wire  [4:0] cv_peid;
    wire        cv_broadcast;
    wire        cv_pecfg;
    wire [12:0] cv_Iext;  // TODO: bit width change to 13
    wire [12:0] cv_Oext;  // TODO: bit width change to 13
    wire [12:0] cv_Hext;  // TODO: bit width change to 13
    wire [12:0] cv_Wext;  // TODO: bit width change to 13
    wire [12:0] cv_Iori;  // TODO: bit width change to 13
    wire [12:0] cv_Oori;  // TODO: bit width change to 13
    wire [12:0] cv_Hori;  // TODO: bit width change to 13
    wire [12:0] cv_Wori;  // TODO: bit width change to 13

    // TODO: rename CVDataLoader to CVEngine
    // TODO: move cv core inside CVProcessor
    wire        cv_core_dout_valid;
    wire        cv_core_dout_ready;
    wire [15:0] cv_core_dout_data;
    wire        cv_core_load_weight;
    wire        cv_core_load_input;
    wire        cv_core_store_output;
    wire        cv_core_calc_done;
    wire        cv_core_idle;

    CVDataLoader u_CVDataLoader (
        .clk(clk),
        .rst(cv_rst),

        .I(cv_I),
        .O(cv_O),
        .K(cv_K),
        .H(cv_H),
        .W(cv_W),
        .Iext(cv_Iext),
        .Oext(cv_Oext),
        .Hext(cv_Hext),
        .Wext(cv_Wext),
        .Iori(cv_Iori),
        .Oori(cv_Oori),
        .Hori(cv_Hori),
        .Wori(cv_Wori),
        .has_bias(has_bias),

        .ifaddr(cv_ifaddr),
        .weaddr(cv_weaddr),
        .ofaddr(cv_ofaddr),

        .core_dout_valid(cv_core_dout_valid),
        .core_dout_ready(cv_core_dout_ready),
        .core_dout_data(cv_core_dout_data),

        .load_weight(cv_load_weight),
        .load_input(cv_load_input),
        .store_output(cv_store_output),

        .core_load_weight(cv_core_load_weight),
        .core_load_input(cv_core_load_input),
        .core_store_output(cv_core_store_output),
        .core_calc_done(cv_core_calc_done),
        .core_idle(cv_core_idle),

        .wvalid(wvalid_[`LAYER_CV]),
        .wready(wready_[`LAYER_CV]),
        .waddr(waddr_[`LAYER_CV]),
        .wdata(wdata_[`LAYER_CV]),
        .rvalid(rvalid_[`LAYER_CV]),
        .rready(rready_[`LAYER_CV]),
        .raddr(raddr_[`LAYER_CV]),
        .rdata(rdata_[`LAYER_CV]),

        .done(cv_done)
    );


    // TODO: multiple PE arbitration
    BehavCVCore u_BehavCVCore (
        .clk(clk),
        .rst(cv_rst),
        .din_valid(rready),
        .din_data(rdata[15:0]),
        .dout_valid(cv_core_dout_valid),
        .dout_ready(cv_core_dout_ready),
        .dout_data(cv_core_dout_data),
        .has_bias(has_bias),
        .act_type(act_type),

        .load_weight(cv_core_load_weight),
        .load_input(cv_core_load_input),
        .store_output(cv_core_store_output),
        .calc_done(cv_core_calc_done),
        .idle(cv_core_idle),

        .K(cv_K),
        .I(cv_I),
        .Iori(cv_Iori),
        .Iext(cv_Iext),
        .Oext(cv_Oext),
        .Hext(cv_Hext),
        .Wext(cv_Wext)
    );

    wire        mp_rst;
    wire [26:0] mp_ifaddr;
    wire [26:0] mp_ofaddr;
    wire        mp_done;

    MPDataLoader u_MPDataLoader (
        .clk(clk),
        .rst(mp_rst),
        .C(cv_O),
        .H(cv_H),
        .W(cv_W),
        .ifaddr(mp_ifaddr),
        .ofaddr(mp_ofaddr),

        .wvalid(wvalid_[`LAYER_MP]),
        .wready(wready_[`LAYER_MP]),
        .waddr(waddr_[`LAYER_MP]),
        .wdata(wdata_[`LAYER_MP]),
        .rvalid(rvalid_[`LAYER_MP]),
        .rready(rready_[`LAYER_MP]),
        .raddr(raddr_[`LAYER_MP]),
        .rdata(rdata_[`LAYER_MP]),

        .done(mp_done)
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
        .fc_base_addr(fc_base_addr),
        .fc_done(fc_done),

        .cv_rst(cv_rst),
        .cv_I(cv_I),
        .cv_O(cv_O),
        .cv_K(cv_K),
        .cv_H(cv_H),
        .cv_W(cv_W),
        .cv_ifaddr(cv_ifaddr),
        .cv_weaddr(cv_weaddr),
        .cv_ofaddr(cv_ofaddr),
        .cv_load_weight(cv_load_weight),
        .cv_load_input(cv_load_input),
        .cv_store_output(cv_store_output),
        .cv_done(cv_done),

        .cv_peid(cv_peid),
        .cv_broadcast(cv_broadcast),
        .cv_pecfg(cv_pecfg),
        .cv_Iext(cv_Iext),
        .cv_Oext(cv_Oext),
        .cv_Hext(cv_Hext),
        .cv_Wext(cv_Wext),
        .cv_Iori(cv_Iori),
        .cv_Oori(cv_Oori),
        .cv_Hori(cv_Hori),
        .cv_Wori(cv_Wori),

        .mp_rst(mp_rst),
        .mp_ifaddr(mp_ifaddr),
        .mp_ofaddr(mp_ofaddr),
        .mp_done(mp_done)
    );
endmodule
