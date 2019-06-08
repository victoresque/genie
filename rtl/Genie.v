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
    assign is_fc = layer_type == `LAYER_FC;
    assign is_cv = layer_type == `LAYER_CV;

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
    assign waddr = waddr_[layer_type[1:0]];
    assign wdata = wdata_[layer_type[1:0]];
    assign rvalid = rvalid_[layer_type[1:0]];
    assign rready_[`LAYER_FC] = rready & is_fc;
    assign rready_[`LAYER_CV] = rready & is_cv;
    assign raddr = raddr_[layer_type[1:0]];
    assign rdata_[`LAYER_FC] = rdata & {32{is_fc}};
    assign rdata_[`LAYER_CV] = rdata & {32{is_cv}};

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
    wire [26:0] fc_base_addr;

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

    wire        cv_rst;
    wire [10:0] cv_I;
    wire [10:0] cv_O;
    wire  [4:0] cv_K;
    wire [10:0] cv_H;
    wire [10:0] cv_W;
    wire [10:0] cv_Oext;
    wire  [7:0] cv_Hext;
    wire  [7:0] cv_Wext;
    wire [10:0] cv_Oori;
    wire  [7:0] cv_Hori;
    wire  [7:0] cv_Wori;
    wire [26:0] cv_ifaddr;
    wire [26:0] cv_weaddr;
    wire [26:0] cv_ofaddr;
    wire  [4:0] cv_peid;
    wire        cv_core_dout_valid;
    wire        cv_core_dout_ready;
    wire [15:0] cv_core_dout_data;
    wire        cv_core_load_weight;
    wire        cv_core_load_input;
    wire        cv_core_store_output;
    wire        cv_core_calc_done;
    wire        cv_load_weight;
    wire        cv_load_input;
    wire        cv_store_output;
    wire        cv_done;

    CVDataLoader u_CVDataLoader (
        .clk(clk),
        .rst(cv_rst),

        .I(cv_I),
        .O(cv_O),
        .K(cv_K),
        .H(cv_H),
        .W(cv_W),
        .Oext(cv_Oext),
        .Hext(cv_Hext),
        .Wext(cv_Wext),
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

        .load_weight(cv_core_load_weight),
        .load_input(cv_core_load_input),
        .store_output(cv_core_store_output),
        .calc_done(cv_core_calc_done),

        .K(cv_K),
        .Iext(cv_I),
        .Oext(cv_Oext),
        .Hext(cv_Hext),
        .Wext(cv_Wext)
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
        .cv_peid(cv_peid),
        .cv_I(cv_I),
        .cv_O(cv_O),
        .cv_K(cv_K),
        .cv_H(cv_H),
        .cv_W(cv_W),
        .cv_Oext(cv_Oext),
        .cv_Hext(cv_Hext),
        .cv_Wext(cv_Wext),
        .cv_Oori(cv_Oori),
        .cv_Hori(cv_Hori),
        .cv_Wori(cv_Wori),
        .cv_ifaddr(cv_ifaddr),
        .cv_weaddr(cv_weaddr),
        .cv_ofaddr(cv_ofaddr),
        
        .cv_load_weight(cv_load_weight),
        .cv_load_input(cv_load_input),
        .cv_store_output(cv_store_output),
        .cv_done(cv_done)
    );
endmodule
