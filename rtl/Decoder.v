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
    input         fc_next_partition,
    input         fc_done,

    // output        conv_lif_start,
    // output        conv_lw_start,
    // input         conv_next_partition,
    // input         conv_done,

    output [26:0] base_addr
);
    reg   [5:0] state, state_next;
    parameter S_INSN_DEC = 0;
    parameter S_CFGL     = 1;
    parameter S_CFGFC    = 2;
    parameter S_FCLIF    = 3;
    parameter S_FCLW     = 4;
    parameter S_FCSOF    = 5;
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

    wire [26:0] base_addr;
    reg  [26:0] base_addr_r, base_addr_w;
    assign base_addr = base_addr_r;

    always @ (*) begin
        iaddr_w = iaddr_r;
        layer_cfg_w = layer_cfg_r;
        fc_cfg_w = fc_cfg_r;
        base_addr_w = base_addr_r;
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
                base_addr_w = idata[26:0];
                state_next = S_FCLIF; 
            end
            `OP_FCLW: begin
                base_addr_w = idata[26:0];
                state_next = S_FCLW; 
            end
            `OP_FCSOF: begin
                base_addr_w = idata[26:0];
                state_next = S_FCSOF; 
            end
            `OP_CFGCV: begin
            end
            `OP_CFGCVIF: begin
            end
            `OP_CVAIF: begin
            end
            `OP_CVAW: begin
            end
            `OP_CVAOF: begin
            end
            `OP_CVSELPE: begin
            end
            `OP_CVCFGPE: begin
            end
            `OP_CVLIFP: begin
            end
            `OP_CVLWP: begin
            end
            `OP_CVSOFP: begin
            end
            `OP_MPLIF: begin
            end
            `OP_MPSOF: begin
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
            base_addr_r <= 0;
            state <= S_INSN_DEC;
        end
        else begin
            iaddr_r <= iaddr_w;
            layer_cfg_r <= layer_cfg_w;
            fc_cfg_r <= fc_cfg_w;
            base_addr_r <= base_addr_w;
            state <= state_next;
        end
    end
endmodule
