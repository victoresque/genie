module Decoder (
    input         clk,
    input         rst_n,
// instruction ROM interface
    output [12:0] iaddr,
    input  [31:0] idata,
// layer-wise signals
    output  [4:0] layer_type,
    output  [4:0] act_type,
    output        has_bias,
// fully-connected
    output        fc_rst,
    output [10:0] fc_cin,
    output [10:0] fc_cout,
    output        fc_lif_start,
    output        fc_lw_start,
    output        fc_sof_start,
    output [26:0] fc_base_addr,
    input         fc_done,
// 2D convolution
    output        cv_rst,
    output [10:0] cv_I,
    output [10:0] cv_O,
    output  [4:0] cv_K,
    output [12:0] cv_H,
    output [12:0] cv_W,
    output [26:0] cv_ifaddr,
    output [26:0] cv_weaddr,
    output [26:0] cv_ofaddr,
    output        cv_load_weight,
    output        cv_load_input,
    output        cv_store_output,
    input         cv_done,
    output  [7:0] cv_peid,
    input         cv_pe_idle,
    output        cv_broadcast,
    output        cv_pecfg,
    output [10:0] cv_Iext,
    output [10:0] cv_Oext,
    output [10:0] cv_Hext,
    output [10:0] cv_Wext,
    output [10:0] cv_Iori,
    output [10:0] cv_Oori,
    output [10:0] cv_Hori,
    output [10:0] cv_Wori,
// max pooling
    output        mp_rst,
    output [26:0] mp_ifaddr,
    output [26:0] mp_ofaddr,
    input         mp_done
);
    reg [6:0] state, state_next;
    parameter S_INSN_DEC = 0;
    parameter S_CFGL     = `OP_CFGL;
    parameter S_CFGFC    = `OP_CFGFC;
    parameter S_FCLIF    = `OP_FCLIF;
    parameter S_FCLW     = `OP_FCLW;
    parameter S_FCSOF    = `OP_FCSOF;
    parameter S_CFGCV    = `OP_CFGCV;
    parameter S_CFGCVIF  = `OP_CFGCVIF;
    parameter S_CVAIF    = `OP_CVAIF;
    parameter S_CVAW     = `OP_CVAW;
    parameter S_CVAOF    = `OP_CVAOF;
    parameter S_CVSELPE  = `OP_CVSELPE;
    parameter S_CVCFGEXT = `OP_CVCFGEXT;
    parameter S_CVCFGORI = `OP_CVCFGORI;
    parameter S_CVLIFP   = `OP_CVLIFP;
    parameter S_CVLWP    = `OP_CVLWP;
    parameter S_CVSOFP   = `OP_CVSOFP;
    parameter S_MPAIF    = `OP_MPAIF;
    parameter S_MPSOF    = `OP_MPSOF;
    parameter S_EOC      = `OP_EOC;

    // instruction address
    reg  [12:0] iaddr_r, iaddr_w;
    assign iaddr = iaddr_r;

    // instruction opcode
    wire  [4:0] opcode;
    assign opcode = idata[31:27];

    // layer configuration
    reg  [26:0] layer_cfg_r, layer_cfg_w;
    assign layer_type = layer_cfg_r[20:16];
    assign act_type = layer_cfg_r[9:5];
    assign has_bias = layer_cfg_r[0];

    // fc specific signals
    wire        is_fc;
    reg  [21:0] fc_cfg_r, fc_cfg_w;
    reg  [26:0] fc_base_addr_r, fc_base_addr_w;
    assign is_fc = layer_type == `LAYER_FC;
    assign fc_rst = state == S_CFGFC;
    assign fc_lif_start = state == S_FCLIF;
    assign fc_lw_start = state == S_FCLW;
    assign fc_sof_start = state == S_FCSOF;
    assign fc_cin = fc_cfg_r[21:11];
    assign fc_cout = fc_cfg_r[10:0];
    assign fc_base_addr = fc_base_addr_r;

    // cv specific signals
    wire        is_cv;
    reg  [26:0] cv_cfg_r, cv_cfg_w;
    reg  [25:0] cv_ifcfg_r, cv_ifcfg_w;
    reg  [25:0] cv_ioext_r, cv_ioext_w;
    reg  [25:0] cv_hwext_r, cv_hwext_w;
    reg  [25:0] cv_ioori_r, cv_ioori_w;
    reg  [25:0] cv_hwori_r, cv_hwori_w;
    reg  [26:0] cv_ifaddr_r, cv_ifaddr_w;
    reg  [26:0] cv_weaddr_r, cv_weaddr_w;
    reg  [26:0] cv_ofaddr_r, cv_ofaddr_w;
    reg   [7:0] cv_peid_r, cv_peid_w;
    reg         cv_broadcast_r, cv_broadcast_w;
    assign is_cv = layer_type == `LAYER_CV;
    assign cv_rst = state == S_CFGCV;
    assign cv_I = cv_cfg_r[26:16];
    assign cv_O = cv_cfg_r[15:5];
    assign cv_K = cv_cfg_r[4:0];
    assign cv_H = cv_ifcfg_r[25:13];
    assign cv_W = cv_ifcfg_r[12:0];
    assign cv_Iext = cv_ioext_r[23:13];
    assign cv_Oext = cv_ioext_r[10:0];
    assign cv_Hext = cv_hwext_r[23:13];
    assign cv_Wext = cv_hwext_r[10:0];
    assign cv_Iori = cv_ioori_r[23:13];
    assign cv_Oori = cv_ioori_r[10:0];
    assign cv_Hori = cv_hwori_r[23:13];
    assign cv_Wori = cv_hwori_r[10:0];
    assign cv_ifaddr = cv_ifaddr_r;
    assign cv_weaddr = cv_weaddr_r;
    assign cv_ofaddr = cv_ofaddr_r;
    assign cv_load_weight = state == S_CVLWP;
    assign cv_load_input = state == S_CVLIFP;
    assign cv_store_output = state == S_CVSOFP;
    assign cv_peid = cv_peid_r;
    assign cv_broadcast = cv_broadcast_r;
    assign cv_pecfg = (state == S_CVCFGEXT) || (state == S_CVCFGORI);

    // maxpool specific signals
    wire        is_mp;
    reg  [26:0] mp_ifaddr_r, mp_ifaddr_w;
    reg  [26:0] mp_ofaddr_r, mp_ofaddr_w;
    reg         mp_rst_r;
    wire        mp_rst_w;
    assign mp_rst_w = state_next == S_MPSOF && !(state == S_MPSOF);
    assign is_mp = layer_type == `LAYER_MP;
    assign mp_rst = mp_rst_r;
    assign mp_ifaddr = mp_ifaddr_r;
    assign mp_ofaddr = mp_ofaddr_r;

    always @ (*) begin
        iaddr_w = iaddr_r;
        layer_cfg_w = layer_cfg_r;
        fc_cfg_w = fc_cfg_r;
        fc_base_addr_w = fc_base_addr_r;
        cv_cfg_w = cv_cfg_r;
        cv_ifcfg_w = cv_ifcfg_r;
        cv_ioext_w = cv_ioext_r;
        cv_hwext_w = cv_hwext_r;
        cv_ioori_w = cv_ioori_r;
        cv_hwori_w = cv_hwori_r;
        cv_ifaddr_w = cv_ifaddr_r;
        cv_weaddr_w = cv_weaddr_r;
        cv_ofaddr_w = cv_ofaddr_r;
        cv_peid_w = cv_peid_r;
        cv_broadcast_w = cv_broadcast_r;
        mp_ifaddr_w = mp_ifaddr_r;
        mp_ofaddr_w = mp_ofaddr_r;
        state_next = state;
        
        case(state)
        S_INSN_DEC: begin
            iaddr_w = iaddr_r + 1;
            case(opcode)
            `OP_CFGL: begin
                layer_cfg_w = idata[26:0];
                state_next = S_CFGL; end
            `OP_CFGFC: begin
                fc_cfg_w = {idata[26:16], idata[15:5]};
                state_next = S_CFGFC; end
            `OP_FCLIF: begin
                fc_base_addr_w = idata[26:0];
                state_next = S_FCLIF; end
            `OP_FCLW: begin
                fc_base_addr_w = idata[26:0];
                state_next = S_FCLW; end
            `OP_FCSOF: begin
                fc_base_addr_w = idata[26:0];
                state_next = S_FCSOF; end
            `OP_CFGCV: begin
                cv_cfg_w = idata[26:0];
                state_next = S_CFGCV; end
            `OP_CFGCVIF: begin
                cv_ifcfg_w = idata[25:0];
                state_next = S_CFGCVIF; end
            `OP_CVAIF: begin
                cv_ifaddr_w = idata[26:0];
                state_next = S_CVAIF; end
            `OP_CVAW: begin
                cv_weaddr_w = idata[26:0];
                state_next = S_CVAW; end
            `OP_CVAOF: begin
                cv_ofaddr_w = idata[26:0];
                state_next = S_CVAOF; end
            `OP_CVSELPE: begin
                cv_broadcast_w = idata[8];
                cv_peid_w = idata[7:0];
                state_next = S_CVSELPE; end
            `OP_CVCFGEXT: begin
                if (cv_pe_idle) begin
                    if (idata[26]) cv_ioext_w = idata[25:0];
                    else           cv_hwext_w = idata[25:0];
                    state_next = S_CVCFGEXT; 
                end
                else begin
                    iaddr_w = iaddr_r;
                end
            end
            `OP_CVCFGORI: begin
                if (cv_pe_idle) begin
                    if (idata[26]) cv_ioori_w = idata[25:0];
                    else           cv_hwori_w = idata[25:0];
                    state_next = S_CVCFGORI; 
                end
                else begin
                    iaddr_w = iaddr_r;
                end
            end
            `OP_CVLIFP: begin
                state_next = S_CVLIFP; end
            `OP_CVLWP: begin
                state_next = S_CVLWP; end
            `OP_CVSOFP: begin
                state_next = S_CVSOFP; end
            `OP_MPAIF: begin
                mp_ifaddr_w = idata[26:0];
                state_next = S_MPAIF; end
            `OP_MPSOF: begin
                mp_ofaddr_w = idata[26:0];
                state_next = S_MPSOF; end
            `OP_EOC: begin
                state_next = S_EOC; end
            endcase
        end
        S_CFGL: begin
            state_next = S_INSN_DEC; end
        S_CFGFC: begin
            state_next = S_INSN_DEC; end
        S_FCLIF: begin
            if (fc_done) state_next = S_INSN_DEC; end
        S_FCLW: begin
            if (fc_done) state_next = S_INSN_DEC; end
        S_FCSOF: begin
            if (fc_done) state_next = S_INSN_DEC; end
        S_CFGCV: begin
            state_next = S_INSN_DEC; end
        S_CFGCVIF: begin
            state_next = S_INSN_DEC; end
        S_CVAIF: begin
            state_next = S_INSN_DEC; end
        S_CVAW: begin
            state_next = S_INSN_DEC; end
        S_CVAOF: begin
            state_next = S_INSN_DEC; end
        S_CVSELPE: begin
            state_next = S_INSN_DEC; end
        S_CVCFGEXT: begin
            state_next = S_INSN_DEC; end
        S_CVCFGORI: begin
            state_next = S_INSN_DEC; end
        S_CVLIFP: begin
            if (cv_done) state_next = S_INSN_DEC; end
        S_CVLWP: begin
            if (cv_done) state_next = S_INSN_DEC; end
        S_CVSOFP: begin
            if (cv_done) state_next = S_INSN_DEC; end
        S_MPAIF: begin
            state_next = S_INSN_DEC; end
        S_MPSOF: begin
            if (mp_done) state_next = S_INSN_DEC; end
        S_EOC: begin
            # (`CYCLE * 10);
            $display(">>>>>>>>>> FINISH <<<<<<<<<<");
            $finish();
        end
        endcase
    end

    always @ (posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            iaddr_r <= 0;
            layer_cfg_r <= 0;
            fc_cfg_r <= 0;
            fc_base_addr_r <= 0;
            cv_cfg_r <= 0;
            cv_ifcfg_r <= 0;
            cv_ioext_r <= 0;
            cv_hwext_r <= 0;
            cv_ioori_r <= 0;
            cv_hwori_r <= 0;
            cv_ifaddr_r <= 0;
            cv_weaddr_r <= 0;
            cv_ofaddr_r <= 0;
            cv_peid_r <= 0;
            cv_broadcast_r <= 0;
            mp_rst_r <= 0;
            mp_ifaddr_r <= 0;
            mp_ofaddr_r <= 0;
            state <= S_INSN_DEC;
        end
        else begin
            iaddr_r <= iaddr_w;
            layer_cfg_r <= layer_cfg_w;
            fc_cfg_r <= fc_cfg_w;
            fc_base_addr_r <= fc_base_addr_w;
            cv_cfg_r <= cv_cfg_w;
            cv_ifcfg_r <= cv_ifcfg_w;
            cv_ioext_r <= cv_ioext_w;
            cv_hwext_r <= cv_hwext_w;
            cv_ioori_r <= cv_ioori_w;
            cv_hwori_r <= cv_hwori_w;
            cv_ifaddr_r <= cv_ifaddr_w;
            cv_weaddr_r <= cv_weaddr_w;
            cv_ofaddr_r <= cv_ofaddr_w;
            cv_peid_r <= cv_peid_w;
            cv_broadcast_r <= cv_broadcast_w;
            mp_rst_r <= mp_rst_w;
            mp_ifaddr_r <= mp_ifaddr_w;
            mp_ofaddr_r <= mp_ofaddr_w;
            state <= state_next;
        end
    end
endmodule
