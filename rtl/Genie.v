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

// layer-wise parameters
    wire  [4:0] layer_type;
    wire  [4:0] act_type;
    wire        has_bias;

// layer identifier for external memory interface arbitration
    wire        is_fc;
    wire        is_cv;
    wire        is_mp;
    wire        wvalid_[0:3];
    wire        wready_[0:3];
    wire [25:0] waddr_[0:3];
    wire [31:0] wdata_[0:3];
    wire        rvalid_[0:3];
    wire        rready_[0:3];
    wire [25:0] raddr_[0:3];
    wire [31:0] rdata_[0:3];
    assign is_fc = layer_type == `LAYER_FC;
    assign is_cv = layer_type == `LAYER_CV;
    assign is_mp = layer_type == `LAYER_MP;
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


//========================================================
// Fully-connected Layer                                ||
//========================================================
    wire        fc_rst;
    wire [10:0] fc_cin;
    wire [10:0] fc_cout;
    wire        fc_lif_start;
    wire        fc_lw_start;
    wire        fc_sof_start;
    wire        fc_done;
    wire [26:0] fc_base_addr;

    FCDataLoader u_FCDataLoader (
        .clk(clk),
        .rst(fc_rst),
    // layer-wise signals
        .cin(fc_cin),
        .cout(fc_cout),
        .has_bias(has_bias),
        .act_type(act_type),
    // decoder control signals
        .lif_start(fc_lif_start),
        .lw_start(fc_lw_start),
        .sof_start(fc_sof_start),
        .base_addr(fc_base_addr),
        .done(fc_done),
    // external interface
        .wvalid(wvalid_[`LAYER_FC]),
        .wready(wready_[`LAYER_FC]),
        .waddr(waddr_[`LAYER_FC]),
        .wdata(wdata_[`LAYER_FC]),
        .rvalid(rvalid_[`LAYER_FC]),
        .rready(rready_[`LAYER_FC]),
        .raddr(raddr_[`LAYER_FC]),
        .rdata(rdata_[`LAYER_FC])
    );


//========================================================
// 2D Convolutional Layer                               ||
//========================================================

// conv2d layer-wise signals
    wire        cv_rst;
    wire [10:0] cv_I;
    wire [10:0] cv_O;
    wire  [4:0] cv_K;
    wire [12:0] cv_H;  // TODO: bit width change to 13
    wire [12:0] cv_W;  // TODO: bit width change to 13
    wire [26:0] cv_ifaddr;
    wire [26:0] cv_weaddr;
    wire [26:0] cv_ofaddr;
// conv2d pe-wise signals
    wire  [7:0] cv_peid;
    wire        cv_broadcast;
    wire        cv_pecfg;
    wire [10:0] cv_cfg_Iext;
    wire [10:0] cv_cfg_Oext;
    wire [10:0] cv_cfg_Hext;
    wire [10:0] cv_cfg_Wext;
    wire [10:0] cv_cfg_Iori;
    wire [10:0] cv_cfg_Oori;
    wire [10:0] cv_cfg_Hori;
    wire [10:0] cv_cfg_Wori;
    wire [10:0] cv_Iext;
    wire [10:0] cv_Oext;
    wire [10:0] cv_Hext;
    wire [10:0] cv_Wext;
    wire [10:0] cv_Iori;
    wire [10:0] cv_Oori;
    wire [10:0] cv_Hori;
    wire [10:0] cv_Wori;
// decoder control signals for data loader
    wire        cv_load_weight;
    wire        cv_load_input;
    wire        cv_store_output;
    wire        cv_done;
// decoder control signals for conv engine
    wire        cv_pe_dout_valid;
    wire        cv_pe_dout_ready;
    wire [15:0] cv_pe_dout_data;
    wire        cv_pe_load_weight;
    wire        cv_pe_load_input;
    wire        cv_pe_store_output;
    wire        cv_pe_idle;

    CVDataLoader u_CVDataLoader (
        .clk(clk),
        .rst(cv_rst),
    // layer-wise signals
        .I(cv_I),
        .O(cv_O),
        .K(cv_K),
        .H(cv_H),
        .W(cv_W),
        .has_bias(has_bias),
        .ifaddr(cv_ifaddr),
        .weaddr(cv_weaddr),
        .ofaddr(cv_ofaddr),
    // PE-wise signals
        .Iext(cv_Iext),
        .Oext(cv_Oext),
        .Hext(cv_Hext),
        .Wext(cv_Wext),
        .Iori(cv_Iori),
        .Oori(cv_Oori),
        .Hori(cv_Hori),
        .Wori(cv_Wori),
    // decoder control signals
        .load_weight(cv_load_weight),
        .load_input(cv_load_input),
        .store_output(cv_store_output),
        .done(cv_done),
    // pe control signals
        .pe_dout_valid(cv_pe_dout_valid),
        .pe_dout_ready(cv_pe_dout_ready),
        .pe_dout_data(cv_pe_dout_data),
        .pe_load_weight(cv_pe_load_weight),
        .pe_load_input(cv_pe_load_input),
        .pe_store_output(cv_pe_store_output),
        .pe_idle(cv_pe_idle),
    // external interface
        .wvalid(wvalid_[`LAYER_CV]),
        .wready(wready_[`LAYER_CV]),
        .waddr(waddr_[`LAYER_CV]),
        .wdata(wdata_[`LAYER_CV]),
        .rvalid(rvalid_[`LAYER_CV]),
        .rready(rready_[`LAYER_CV]),
        .raddr(raddr_[`LAYER_CV]),
        .rdata(rdata_[`LAYER_CV])
    );

    CVEngine u_CVEngine (
        .clk(clk),
        .rst(cv_rst),
        .id(cv_peid),
        .broadcast(cv_broadcast),
        .cfg(cv_pecfg),
    // data loader signals
        .din_valid(rready),
        .din_data(rdata[15:0]),
        .dout_valid(cv_pe_dout_valid),
        .dout_ready(cv_pe_dout_ready),
        .dout_data(cv_pe_dout_data),
        .load_weight(cv_pe_load_weight),
        .load_input(cv_pe_load_input),
        .store_output(cv_pe_store_output),
        .idle(cv_pe_idle),
    // decoder configuration parameter inputs
        .cfg_Iext(cv_cfg_Iext),
        .cfg_Oext(cv_cfg_Oext),
        .cfg_Hext(cv_cfg_Hext),
        .cfg_Wext(cv_cfg_Wext),
        .cfg_Iori(cv_cfg_Iori),
        .cfg_Oori(cv_cfg_Oori),
        .cfg_Hori(cv_cfg_Hori),
        .cfg_Wori(cv_cfg_Wori),
    // PE-wise parameter outputs
        .Iext(cv_Iext),
        .Oext(cv_Oext),
        .Hext(cv_Hext),
        .Wext(cv_Wext),
        .Iori(cv_Iori),
        .Oori(cv_Oori),
        .Hori(cv_Hori),
        .Wori(cv_Wori),
    // layer-wise parameters
        .has_bias(has_bias),
        .act_type(act_type),
        .I(cv_I),
        .O(cv_O),
        .K(cv_K),
        .H(cv_H),
        .W(cv_W)
    );


//========================================================
// Max Pooling Layer                                    ||
//========================================================

    wire        mp_rst;
    wire [26:0] mp_ifaddr;
    wire [26:0] mp_ofaddr;
    wire        mp_done;

    MPDataLoader u_MPDataLoader (
        .clk(clk),
        .rst(mp_rst),
    // layer-wise signals
        .C(cv_O),
        .H(cv_H),
        .W(cv_W),
        .ifaddr(mp_ifaddr),
        .ofaddr(mp_ofaddr),
    // external interface
        .wvalid(wvalid_[`LAYER_MP]),
        .wready(wready_[`LAYER_MP]),
        .waddr(waddr_[`LAYER_MP]),
        .wdata(wdata_[`LAYER_MP]),
        .rvalid(rvalid_[`LAYER_MP]),
        .rready(rready_[`LAYER_MP]),
        .raddr(raddr_[`LAYER_MP]),
        .rdata(rdata_[`LAYER_MP]),
    // decoder control signals
        .done(mp_done)
    );


//========================================================
// Instruction Decoder                                  ||
//========================================================

    Decoder u_Decoder (
        .clk(clk),
        .rst_n(rst_n),
    // instruction ROM interface
        .iaddr(iaddr),
        .idata(idata),
    // common layer-wise interface
        .layer_type(layer_type),
        .act_type(act_type),
        .has_bias(has_bias),
    // fully-connected
        .fc_rst(fc_rst),
        .fc_cin(fc_cin),
        .fc_cout(fc_cout),
        .fc_lif_start(fc_lif_start),
        .fc_lw_start(fc_lw_start),
        .fc_sof_start(fc_sof_start),
        .fc_base_addr(fc_base_addr),
        .fc_done(fc_done),
    // 2D convolution
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
        .cv_pe_idle(cv_pe_idle),
        .cv_broadcast(cv_broadcast),
        .cv_pecfg(cv_pecfg),
        .cv_Iext(cv_cfg_Iext),
        .cv_Oext(cv_cfg_Oext),
        .cv_Hext(cv_cfg_Hext),
        .cv_Wext(cv_cfg_Wext),
        .cv_Iori(cv_cfg_Iori),
        .cv_Oori(cv_cfg_Oori),
        .cv_Hori(cv_cfg_Hori),
        .cv_Wori(cv_cfg_Wori),
    // max pooling
        .mp_rst(mp_rst),
        .mp_ifaddr(mp_ifaddr),
        .mp_ofaddr(mp_ofaddr),
        .mp_done(mp_done)
    );
endmodule
