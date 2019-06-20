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
    reg         dout_valid;
    reg  [15:0] dout_data;
    reg         idle;
    reg  [12:0] Iext;
    reg  [12:0] Oext;
    reg  [12:0] Hext;
    reg  [12:0] Wext;
    reg  [12:0] Iori;
    reg  [12:0] Oori;
    reg  [12:0] Hori;
    reg  [12:0] Wori;
    
    integer i;

    genvar peid;
    generate
        for (peid = 0; peid < 4; peid = peid + 1) begin: core
            wire        dout_valid;
            wire [15:0] dout_data;
            wire        idle;
            wire [12:0] Iext;
            wire [12:0] Oext;
            wire [12:0] Hext;
            wire [12:0] Wext;
            wire [12:0] Iori;
            wire [12:0] Oori;
            wire [12:0] Hori;
            wire [12:0] Wori;
            CVCoreWrapper # (
                .PEID(peid)
            ) u_CVCoreWrapper (
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
        end
    endgenerate

    always @ (*) begin
        dout_valid = (core[0].dout_valid & {1{id==0}})
                   | (core[1].dout_valid & {1{id==1}})
                   | (core[2].dout_valid & {1{id==2}})
                   | (core[3].dout_valid & {1{id==3}});
        dout_data = (core[0].dout_data & {16{id==0}})
                  | (core[1].dout_data & {16{id==1}})
                  | (core[2].dout_data & {16{id==2}})
                  | (core[3].dout_data & {16{id==3}});
        idle = core[0].idle;
        Iext = (core[0].Iext & {13{id==0}})
             | (core[1].Iext & {13{id==1}})
             | (core[2].Iext & {13{id==2}})
             | (core[3].Iext & {13{id==3}});
        Oext = (core[0].Oext & {13{id==0}})
             | (core[1].Oext & {13{id==1}})
             | (core[2].Oext & {13{id==2}})
             | (core[3].Oext & {13{id==3}});
        Hext = (core[0].Hext & {13{id==0}})
             | (core[1].Hext & {13{id==1}})
             | (core[2].Hext & {13{id==2}})
             | (core[3].Hext & {13{id==3}});
        Wext = (core[0].Wext & {13{id==0}})
             | (core[1].Wext & {13{id==1}})
             | (core[2].Wext & {13{id==2}})
             | (core[3].Wext & {13{id==3}});
        Iori = (core[0].Iori & {13{id==0}})
             | (core[1].Iori & {13{id==1}})
             | (core[2].Iori & {13{id==2}})
             | (core[3].Iori & {13{id==3}});
        Oori = (core[0].Oori & {13{id==0}})
             | (core[1].Oori & {13{id==1}})
             | (core[2].Oori & {13{id==2}})
             | (core[3].Oori & {13{id==3}});
        Hori = (core[0].Hori & {13{id==0}})
             | (core[1].Hori & {13{id==1}})
             | (core[2].Hori & {13{id==2}})
             | (core[3].Hori & {13{id==3}});
        Wori = (core[0].Wori & {13{id==0}})
             | (core[1].Wori & {13{id==1}})
             | (core[2].Wori & {13{id==2}})
             | (core[3].Wori & {13{id==3}});
    end
endmodule
