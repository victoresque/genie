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
    input   [4:0] K,
    input  [12:0] I
);
    parameter PEID = 0;

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

    BehavCVCore u_BehavCVCore (
        .clk(clk),
        .rst(rst),
        .din_valid(din_valid),
        .din_data(din_data),
        .dout_valid(dout_valid),
        .dout_ready(dout_ready),
        .dout_data(dout_data),
        .has_bias(has_bias),
        .act_type(act_type),

        .load_weight(load_weight),
        .load_input(load_input),
        .store_output(store_output),
        .idle(idle),

        .K(K),
        .I(I),
        .Iori(Iori_r),
        .Iext(Iext_r),
        .Oext(Oext_r),
        .Hext(Hext_r),
        .Wext(Wext_r)
    );

    always @ (*) begin
        Iext_w = Iext_r;
        Oext_w = Oext_r;
        Hext_w = Hext_r;
        Wext_w = Wext_r;
        Iori_w = Iori_r;
        Oori_w = Oori_r;
        Hori_w = Hori_r;
        Wori_w = Wori_r;

        if (id == PEID || broadcast) begin
            if (cfg) begin
                Iext_w = cfg_Iext;
                Oext_w = cfg_Oext;
                Hext_w = cfg_Hext;
                Wext_w = cfg_Wext;
                Iori_w = cfg_Iori;
                Oori_w = cfg_Oori;
                Hori_w = cfg_Hori;
                Wori_w = cfg_Wori;
            end
        end
    end

    always @ (posedge clk) begin
        if (rst) begin
            Iext_r <= 0;
            Oext_r <= 0;
            Hext_r <= 0;
            Wext_r <= 0;
            Iori_r <= 0;
            Oori_r <= 0;
            Hori_r <= 0;
            Wori_r <= 0;
        end
        else begin
            Iext_r <= Iext_w;
            Oext_r <= Oext_w;
            Hext_r <= Hext_w;
            Wext_r <= Wext_w;
            Iori_r <= Iori_w;
            Oori_r <= Oori_w;
            Hori_r <= Hori_w;
            Wori_r <= Wori_w;
        end
    end
endmodule

