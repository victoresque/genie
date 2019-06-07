module Decoder (
    input         clk,
    input         rst_n,
    output [12:0] iaddr,
    input  [31:0] idata,

    output  [4:0] layer_type,
    output  [4:0] act_type,
    output        has_bias,

    output        fc_rst,
    output [11:0] fc_cin,
    output [11:0] fc_cout,
    output        fc_lif_start,
    output        fc_lw_start,
    output        fc_sof_start,
    output [26:0] fc_base_addr,
    input         fc_done,

    output        cv_rst,
    output [10:0] cv_I,
    output [10:0] cv_O,
    output  [4:0] cv_K,
    output [10:0] cv_H,
    output [10:0] cv_W,
    output [10:0] cv_Oext,
    output  [7:0] cv_Hext,
    output  [7:0] cv_Wext,
    output [10:0] cv_Oori,
    output  [7:0] cv_Hori,
    output  [7:0] cv_Wori,
    output [26:0] cv_ifaddr,
    output [26:0] cv_waddr,
    output [26:0] cv_ofaddr,
    output  [4:0] cv_peid
);
    reg   [5:0] state, state_next;
    parameter S_INSN_DEC = 0;
    parameter S_CFGL     = 1;
    parameter S_CFGFC    = 2;
    parameter S_FCLIF    = 3;
    parameter S_FCLW     = 4;
    parameter S_FCSOF    = 5;
    parameter S_CFGCV    = 11;
    parameter S_CFGCVIF  = 12;
    parameter S_CVAIF    = 13;
    parameter S_CVAW     = 14;
    parameter S_CVAOF    = 15;
    parameter S_CVSELPE  = 16;
    parameter S_CVCFGPE  = 17;
    parameter S_CVLIFP   = 18;
    parameter S_CVLWP    = 19;
    parameter S_CVSOFP   = 20;
    parameter S_MPLIF    = 28;
    parameter S_MPSOF    = 29;
    parameter S_EOC      = 31;

    reg  [12:0] iaddr_r, iaddr_w;
    wire  [4:0] opcode;
    assign iaddr = iaddr_r;
    assign opcode = idata[31:27];

    reg  [10:0] layer_cfg_r, layer_cfg_w;

    wire  [4:0] layer_type;
    wire  [4:0] act_type;
    wire        has_bias;
    assign layer_type = layer_cfg_r[10:6];
    assign act_type = layer_cfg_r[5:1];
    assign has_bias = layer_cfg_r[0];

    wire        is_fc;
    reg  [21:0] fc_cfg_r, fc_cfg_w;
    wire [11:0] fc_cin;
    wire [11:0] fc_cout;
    assign is_fc = layer_type == `LAYER_FC;
    assign fc_rst = state == S_CFGFC;
    assign fc_lif_start = state == S_FCLIF;
    assign fc_lw_start = state == S_FCLW;
    assign fc_sof_start = state == S_FCSOF;
    assign fc_cin = fc_cfg_r[21:11];
    assign fc_cout = fc_cfg_r[10:0];

    wire [26:0] fc_base_addr;
    reg  [26:0] fc_base_addr_r, fc_base_addr_w;
    assign fc_base_addr = fc_base_addr_r;

    wire        if_cv;
    wire        cv_rst;
    reg  [26:0] cv_cfg_r, cv_cfg_w;
    reg  [21:0] cv_ifcfg_r, cv_ifcfg_w;
    reg  [26:0] cv_pecfg_r, cv_pecfg_w;
    reg  [15:0] cv_ifori_r, cv_ifori_w;
    reg  [10:0] cv_wori_r, cv_wori_w;
    reg  [26:0] cv_ifaddr_r, cv_ifaddr_w;
    reg  [26:0] cv_waddr_r, cv_waddr_w;
    reg  [26:0] cv_ofaddr_r, cv_ofaddr_w;

    assign is_cv = layer_type == `LAYER_CONV;
    assign cv_rst = state == S_CFGCV;
    assign cv_I = cv_cfg_r[26:16];
    assign cv_O = cv_cfg_r[15:5];
    assign cv_K = cv_cfg_r[4:0];
    assign cv_H = cv_ifcfg_r[21:11];
    assign cv_W = cv_ifcfg_r[10:0];
    assign cv_Oext = cv_pecfg_r[26:16];
    assign cv_Hext = cv_pecfg_r[15:8];
    assign cv_Wext = cv_pecfg_r[7:0];
    assign cv_Oori = cv_wori_r[10:0];
    assign cv_Hori = cv_ifori_r[15:8];
    assign cv_Wori = cv_ifori_r[7:0];
    assign cv_ifaddr = cv_ifaddr_r;
    assign cv_waddr = cv_waddr_r;
    assign cv_ofaddr = cv_ofaddr_r;
    assign cv_peid = 0;

    always @ (*) begin
        iaddr_w = iaddr_r;
        layer_cfg_w = layer_cfg_r;
        fc_cfg_w = fc_cfg_r;
        fc_base_addr_w = fc_base_addr_r;
        cv_cfg_w = cv_cfg_r;
        cv_ifcfg_w = cv_ifcfg_r;
        cv_pecfg_w = cv_pecfg_r;
        cv_ifori_w = cv_ifori_r;
        cv_wori_w = cv_wori_r;
        cv_ifaddr_w = cv_ifaddr_r;
        cv_waddr_w = cv_waddr_r;
        cv_ofaddr_w = cv_ofaddr_r;
        state_next = state;
        case(state)
        S_INSN_DEC: begin
            case(opcode)
            `OP_CFGL: begin
                layer_cfg_w = {idata[20:16], idata[9:5], idata[0]};
                state_next = S_CFGL; 
            end
            `OP_CFGFC: begin
                fc_cfg_w = {idata[26:16], idata[15:5]};
                state_next = S_CFGFC; 
            end
            `OP_FCLIF: begin
                fc_base_addr_w = idata[26:0];
                state_next = S_FCLIF; 
            end
            `OP_FCLW: begin
                fc_base_addr_w = idata[26:0];
                state_next = S_FCLW; 
            end
            `OP_FCSOF: begin
                fc_base_addr_w = idata[26:0];
                state_next = S_FCSOF; 
            end
            `OP_CFGCV: begin
                cv_cfg_w = idata[26:0];
                state_next = S_CFGCV;
            end
            `OP_CFGCVIF: begin
                cv_ifcfg_w = idata[26:5];
                state_next = S_CFGCVIF;
            end
            `OP_CVAIF: begin
                cv_ifaddr_w = idata[26:0];
                state_next = S_CVAIF;
            end
            `OP_CVAW: begin
                cv_waddr_w = idata[26:0];
                state_next = S_CVAW;
            end
            `OP_CVAOF: begin
                cv_ofaddr_w = idata[26:0];
                state_next = S_CVAOF;
            end
            `OP_CVSELPE: begin
                state_next = S_CVSELPE;
            end
            `OP_CVCFGPE: begin
                cv_pecfg_w = idata[26:0];
                state_next = S_CVCFGPE;
            end
            `OP_CVLIFP: begin
                cv_ifori_w = idata[15:0];
                state_next = S_CVLIFP;
            end
            `OP_CVLWP: begin
                cv_wori_w = idata[26:16];
                state_next = S_CVLWP;
            end
            `OP_CVSOFP: begin
                state_next = S_CVSOFP;
            end
            `OP_MPLIF: begin
                state_next = S_MPLIF;
            end
            `OP_MPSOF: begin
                state_next = S_MPSOF;
            end
            `OP_EOC: begin
                state_next = S_EOC; 
            end
            endcase
            iaddr_w = iaddr_r + 1;
        end
        S_CFGL: begin
            state_next = S_INSN_DEC;
        end
        S_CFGFC: begin
            state_next = S_INSN_DEC;
        end
        S_FCLIF: begin
            if (fc_done) begin
                state_next = S_INSN_DEC;
            end
        end
        S_FCLW: begin
            if (fc_done) begin
                state_next = S_INSN_DEC;
            end
        end
        S_FCSOF: begin
            if (fc_done) begin
                state_next = S_INSN_DEC;
            end
        end
        S_CFGCV: begin
            state_next = S_INSN_DEC;
        end
        S_CFGCVIF: begin
            state_next = S_INSN_DEC;
        end
        S_CVAIF: begin
            state_next = S_INSN_DEC;
        end
        S_CVAW: begin
            state_next = S_INSN_DEC;
        end
        S_CVAOF: begin
            state_next = S_INSN_DEC;
        end
        S_CVSELPE: begin
            state_next = S_INSN_DEC;
        end
        S_CVCFGPE: begin
            state_next = S_INSN_DEC;
        end
        S_CVLIFP: begin
            state_next = S_INSN_DEC;
        end
        S_CVLWP: begin
            state_next = S_INSN_DEC;
        end
        S_CVSOFP: begin
            state_next = S_INSN_DEC;
        end
        S_MPLIF: begin
            state_next = S_INSN_DEC;
        end
        S_MPSOF: begin
            state_next = S_INSN_DEC;
        end
        S_EOC: begin
            # (`CYCLE * 10);
            $display("FINISH");
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
            cv_pecfg_r <= 0;
            cv_ifori_r <= 0;
            cv_wori_r <= 0;
            cv_ifaddr_r <= 0;
            cv_waddr_r <= 0;
            cv_ofaddr_r <= 0;
            state <= S_INSN_DEC;
        end
        else begin
            iaddr_r <= iaddr_w;
            layer_cfg_r <= layer_cfg_w;
            fc_cfg_r <= fc_cfg_w;
            fc_base_addr_r <= fc_base_addr_w;
            cv_cfg_r <= cv_cfg_w;
            cv_ifcfg_r <= cv_ifcfg_w;
            cv_pecfg_r <= cv_pecfg_w;
            cv_ifori_r <= cv_ifori_w;
            cv_wori_r <= cv_wori_w;
            cv_ifaddr_r <= cv_ifaddr_w;
            cv_waddr_r <= cv_waddr_w;
            cv_ofaddr_r <= cv_ofaddr_w;
            state <= state_next;
        end
    end
endmodule
