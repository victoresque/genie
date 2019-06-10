module CVEngine (
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
    input  [12:0] I,
    input  [12:0] O,
    input   [4:0] K,
    input  [12:0] H,
    input  [12:0] W
);

    CVCorePE # (
        .PEID(0)
    ) u_CVCorePE (
        .clk(clk),
        .rst(rst),
        .id(id),
        .broadcast(broadcast),
        .cfg(cfg),

        // data loader signals
        .din_valid(din_valid),
        .din_data(din_data),
        .dout_valid(dout_valid),
        .dout_ready(dout_ready),
        .dout_data(dout_data),

        // control signals
        .load_weight(load_weight),
        .load_input(load_input),
        .store_output(store_output),
        .idle(idle),

        // PE-wise parameters
        .cfg_Iext(cfg_Iext),
        .cfg_Oext(cfg_Oext),
        .cfg_Hext(cfg_Hext),
        .cfg_Wext(cfg_Wext),
        .cfg_Iori(cfg_Iori),
        .cfg_Oori(cfg_Oori),
        .cfg_Hori(cfg_Hori),
        .cfg_Wori(cfg_Wori),
        .Iext(Iext),
        .Oext(Oext),
        .Hext(Hext),
        .Wext(Wext),
        .Iori(Iori),
        .Oori(Oori),
        .Hori(Hori),
        .Wori(Wori),

        // layer-wise parameters
        .has_bias(has_bias),
        .act_type(act_type),
        .K(K),
        .I(I)
    );

endmodule
