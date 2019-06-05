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

    wire [26:0] base_addr;

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

        .base_addr(base_addr),
        .wvalid(wvalid),
        .wready(wready),
        .waddr(waddr),
        .wdata(wdata),
        .rvalid(rvalid),
        .rready(rready),
        .raddr(raddr),
        .rdata(rdata),

        .done(fc_done)
    );

    FCCore u_FCCore (
        .clk(clk),
        .rst(fc_rst),
        // TODO: pack cfg
        .cin(fc_cin),
        .cout(fc_cout),
        .has_bias(has_bias),
        .din_valid(rready),
        .din_data(rdata[15:0]),
        .dout_valid(fc_dout_valid),
        .dout_ready(fc_dout_ready),
        .dout_data(fc_dout_data)
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
        .fc_next_partition(1'b0),
        .fc_done(fc_done),

        .base_addr(base_addr)
    );
endmodule


module FCDataLoader (
    input         clk,
    input         rst,

    input  [11:0] cin,
    input  [11:0] cout,
    input         has_bias,

    input         lif_start,
    input         lw_start,
    input         sof_start,

    input         fc_dout_valid,
    output        fc_dout_ready,
    input  [15:0] fc_dout_data,

    input  [26:0] base_addr,
    output        wvalid,
    input         wready,
    output [25:0] waddr,
    output [31:0] wdata,
    output        rvalid,
    input         rready,
    output [25:0] raddr,
    input  [31:0] rdata,

    output        done
);
    reg   [2:0] state, state_next;
    parameter S_IDLE        = 0;
    parameter S_LIF         = 1;
    parameter S_LW          = 2;
    parameter S_LB          = 3;
    parameter S_SOF         = 4;
    parameter S_DONE        = 5;

    reg  [25:0] waddr_r, waddr_w;
    reg  [25:0] raddr_r, raddr_w;
    reg         wvalid_r, wvalid_w;
    reg         rvalid_r, rvalid_w;
    reg  [31:0] wdata_r, wdata_w;
    reg         waiting_r, waiting_w;
    reg  [31:0] cnt_r, cnt_w;

    assign waddr = waddr_r;
    assign raddr = raddr_r;
    assign wvalid = wvalid_r;
    assign rvalid = rvalid_r;
    assign wdata = wdata_r;
    assign done = state == S_DONE;

    reg  [23:0] total_weight_r;
    wire [23:0] total_weight_w;
    assign total_weight_w = cin * cout;

    reg         fc_dout_ready_r, fc_dout_ready_w;
    assign fc_dout_ready = fc_dout_ready_r;

    always @ (*) begin
        cnt_w = cnt_r;
        waddr_w = waddr_r;
        raddr_w = raddr_r;
        wvalid_w = wvalid_r;
        rvalid_w = rvalid_r;
        wdata_w = wdata_r;
        waiting_w = waiting_r;
        fc_dout_ready_w = 1'b0;
        state_next = state;
    
        case(state)
        S_IDLE: begin
            if (lif_start) begin
                state_next = S_LIF;
            end
            else if (lw_start) begin
                state_next = S_LW;
            end
            else if (sof_start) begin
                state_next = S_SOF;
            end
            waiting_w = 0;
            cnt_w = 0;
        end
        S_LIF: begin
            if (cnt_r == cin) begin
                state_next = S_DONE;
            end
            else begin
                if (~waiting_r) begin
                    rvalid_w = 1'b1;
                    raddr_w = base_addr + cnt_r;
                    waiting_w = 1;
                end
                else if (rready) begin
                    rvalid_w = 1'b0;
                    cnt_w = cnt_r + 1;
                    waiting_w = 0;
                end
            end
        end
        S_LW: begin
            if (cnt_r == total_weight_r) begin
                if (has_bias) begin
                    cnt_w = 0;
                    state_next = S_LB;
                end
                else begin
                    state_next = S_DONE;
                end
            end
            else begin
                if (~waiting_r) begin
                    rvalid_w = 1'b1;
                    raddr_w = base_addr + cnt_r;
                    waiting_w = 1;
                end
                else if (rready) begin
                    rvalid_w = 1'b0;
                    cnt_w = cnt_r + 1;
                    waiting_w = 0;
                end
            end
        end
        S_LB: begin
            if (cnt_r == cout) begin
                state_next = S_DONE;
            end
            else begin
                if (~waiting_r) begin
                    rvalid_w = 1'b1;
                    raddr_w = base_addr + total_weight_r + cnt_r;
                    waiting_w = 1;
                end
                else if (rready) begin
                    rvalid_w = 1'b0;
                    cnt_w = cnt_r + 1;
                    waiting_w = 0;
                end
            end
        end
        S_SOF: begin
            if (cnt_r == cout) begin
                state_next = S_DONE;
            end
            else begin
                if (~waiting_r) begin
                    if (fc_dout_valid) begin
                        wvalid_w = 1'b1;
                        waddr_w = base_addr + cnt_r;
                        wdata_w = {16'b0, fc_dout_data};
                        fc_dout_ready_w = 1'b1;
                        waiting_w = 1;
                    end
                end
                else if (wready) begin
                    wvalid_w = 1'b0;
                    cnt_w = cnt_r + 1;
                    waiting_w = 0;
                end
            end
        end
        S_DONE: begin
            state_next = S_IDLE;
        end
        endcase
    end

    always @ (posedge clk) begin
        if (rst) begin
            cnt_r <= 0;
            waddr_r <= 0;
            raddr_r <= 0;
            wvalid_r <= 0;
            rvalid_r <= 0;
            wdata_r <= 0;
            waiting_r <= 0;
            total_weight_r <= 0;
            fc_dout_ready_r <= 0;
            state <= S_IDLE;
        end
        else begin
            cnt_r <= cnt_w;
            waddr_r <= waddr_w;
            raddr_r <= raddr_w;
            wvalid_r <= wvalid_w;
            rvalid_r <= rvalid_w;
            wdata_r <= wdata_w;
            waiting_r <= waiting_w;
            total_weight_r <= total_weight_w;
            fc_dout_ready_r <= fc_dout_ready_w;
            state <= state_next;
        end
    end
endmodule

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
    parameter S_INSN_DEC    = 0;
    parameter S_CFGL        = 1;
    parameter S_CFGFC       = 2;
    parameter S_LIF         = 3;
    parameter S_LW          = 4;
    parameter S_SOF         = 5;
    parameter S_EOC         = 31;

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

    reg  [21:0] fc_cfg_r, fc_cfg_w;
    wire [11:0] fc_cin;
    wire [11:0] fc_cout;
    assign fc_rst = state == S_CFGFC;
    assign fc_lif_start = (layer_type == `LAYER_FC) && (state == S_LIF);
    assign fc_lw_start = (layer_type == `LAYER_FC) && (state == S_LW);
    assign fc_sof_start = (layer_type == `LAYER_FC) && (state == S_SOF);
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
            `OP_LIF: begin
                base_addr_w = idata[26:0];
                state_next = S_LIF;
            end
            `OP_LW: begin
                base_addr_w = idata[26:0];
                state_next = S_LW;
            end
            `OP_SOF: begin
                base_addr_w = idata[26:0];
                state_next = S_SOF;
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
        S_LIF: begin
            if ((layer_type == `LAYER_FC) && fc_done) begin
                state_next = S_INSN_DEC;
            end
        end
        S_LW: begin
            if ((layer_type == `LAYER_FC) && fc_done) begin
                state_next = S_INSN_DEC;
            end
        end
        S_SOF: begin
            if ((layer_type == `LAYER_FC) && fc_done) begin
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
