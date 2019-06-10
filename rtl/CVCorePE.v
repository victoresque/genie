module CVCorePE (
    input         clk,
    input         rst,
    input   [7:0] id,
    input         broadcast,
    input         cfg,

    // data loader signals
    input         din_valid,
    input  [15:0] din_data,
    output        dout_valid,
    input         dout_ready,
    output [15:0] dout_data,

    // control signals
    input         load_weight,
    input         load_input,
    input         store_output,
    output        calc_done,
    output        idle,

    // PE-wise parameters
    input  [12:0] cfg_Iext,
    input  [12:0] cfg_Oext,
    input  [12:0] cfg_Hext,
    input  [12:0] cfg_Wext,
    input  [12:0] cfg_Iori,
    input  [12:0] cfg_Oori,
    input  [12:0] cfg_Hori,
    input  [12:0] cfg_Wori,
    output [12:0] Iext,
    output [12:0] Oext,
    output [12:0] Hext,
    output [12:0] Wext,
    output [12:0] Iori,
    output [12:0] Oori,
    output [12:0] Hori,
    output [12:0] Wori,

    // layer-wise parameters
    input         has_bias,
    input   [4:0] act_type,
    input  [12:0] K,
    input  [12:0] I
);
    reg  [12:0] Iext_r, Iext_w;
    reg  [12:0] Oext_r, Oext_w;
    reg  [12:0] Hext_r, Hext_w;
    reg  [12:0] Wext_r, Wext_w;
    reg  [12:0] Iori_r, Iori_w;
    reg  [12:0] Oori_r, Oori_w;
    reg  [12:0] Hori_r, Hori_w;
    reg  [12:0] Wori_r, Wori_w;

    assign Iext = Iext_r;
    assign Oext = Oext_r;
    assign Hext = Hext_r;
    assign Wext = Wext_r;
    assign Iori = Iori_r;
    assign Oori = Oori_r;
    assign Hori = Hori_r;
    assign Wori = Wori_r;
endmodule

