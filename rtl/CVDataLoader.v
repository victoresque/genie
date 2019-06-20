module CVDataLoader (
    input         clk,
    input         rst,
// layer-wise signals
    input  [10:0] I,
    input  [10:0] O,
    input   [4:0] K,
    input  [10:0] H,
    input  [10:0] W,
    input   [1:0] pad,
    input         has_bias,
    input  [26:0] ifaddr,
    input  [26:0] weaddr,
    input  [26:0] ofaddr,
// PE-wise signals
    input  [12:0] Iext,
    input  [12:0] Oext,
    input  [12:0] Hext,
    input  [12:0] Wext,
    input  [12:0] Iori,
    input  [12:0] Oori,
    input  [12:0] Hori,
    input  [12:0] Wori,
// PE control signals
    input         pe_dout_valid,
    output        pe_dout_ready,
    input  [15:0] pe_dout_data,
// decoder control signals
    input         load_weight,
    input         load_input,
    input         store_output,
    output        done,
// control signals to PE
    output        pe_load_weight,
    output        pe_load_input,
    output        pe_store_output,
    input         pe_idle,
// external memory interface
    output        wvalid,
    input         wready,
    output [25:0] waddr,
    output [31:0] wdata,
    output        rvalid,
    input         rready,
    output [25:0] raddr,
    input  [31:0] rdata,
// CVEngine data (for padding)
    output [15:0] pedata
);

// states
    reg   [2:0] state, state_next;
    parameter S_IDLE = 0;
    parameter S_LW   = 1;
    parameter S_LB   = 2;
    parameter S_LIF  = 3;
    parameter S_SOF  = 4;
    parameter S_DONE = 5;

// external memory interface
    reg  [25:0] waddr_r, waddr_w;
    reg  [25:0] raddr_r, raddr_w;
    reg         wvalid_r, wvalid_w;
    reg         rvalid_r, rvalid_w;
    reg  [31:0] wdata_r, wdata_w;
    reg         waiting_r, waiting_w;
    assign waddr = waddr_r;
    assign raddr = raddr_r;
    assign wvalid = wvalid_r;
    assign rvalid = rvalid_r;
    assign wdata = wdata_r;

// feature index counters
    wire [12:0] Hout;
    wire [12:0] Wout;
    reg  [12:0] h_w, h_r;
    reg  [12:0] w_w, w_r;
    reg  [12:0] o_w, o_r;
    reg  [12:0] i_w, i_r;
    reg  [31:0] cnt_r, cnt_w;
    assign Hout = Hext - K + 1;
    assign Wout = Wext - K + 1;

// signed additions are calculated here to prevent Verilog numerical errors 
    wire [12:0] Hori_plus_h;
    wire [12:0] Hori_plus_h_plus_pad;
    wire [12:0] Wori_plus_w;
    wire [12:0] Wori_plus_w_plus_pad;
    assign Hori_plus_h = Hori + h_r;
    assign Hori_plus_h_plus_pad = Hori + h_r + pad;
    assign Wori_plus_w = Wori + w_r;
    assign Wori_plus_w_plus_pad = Wori + w_r + pad;

// control signals    
    reg         pe_dout_ready_w, pe_dout_ready_r;
    assign pe_dout_ready = pe_dout_ready_w;
    assign done = state == S_DONE;
    assign pe_load_weight = state == S_LW;
    assign pe_load_input = state == S_LIF;
    assign pe_store_output = state == S_SOF;
    
    reg         is_pad_r, is_pad_w;
    assign pedata = is_pad_r ? 0 : rdata[15:0];

    always @ (*) begin
        cnt_w = cnt_r;
        waddr_w = waddr_r;
        raddr_w = raddr_r;
        wvalid_w = wvalid_r;
        rvalid_w = rvalid_r;
        wdata_w = wdata_r;
        waiting_w = waiting_r;
        pe_dout_ready_w = 1'b0;
        h_w = h_r;
        w_w = w_r;
        o_w = o_r;
        i_w = i_r;
        is_pad_w = is_pad_r;
        state_next = state;

        case(state)
            // S_IDLE:
            //      if PE is idle, then wait for load_weight, load_input, or store_output
            //      1. load_weight:  S_LW     
            //      2. load_input:   S_LIF
            //      3. store_output: S_SOF
            //
            //      if not broadcasting, when 'pe_idle' is high, the "selected" PE is idle
            //      if broadcasting, 'pe_idle' is high when all PEs are idle
            S_IDLE: begin
                h_w = 0;
                w_w = 0;
                o_w = 0;
                i_w = 0;
                rvalid_w = 1'b0;
                wvalid_w = 1'b0;
                waiting_w = 0;
                cnt_w = 0;
                if (load_weight && pe_idle) begin
                    rvalid_w = 1'b1;
                    is_pad_w = 0;
                    raddr_w = weaddr + Oori * I * K * K;
                    cnt_w = 1;
                    state_next = S_LW;
                end
                else if (load_input && pe_idle) begin
                    rvalid_w = 1'b1;
                    is_pad_w = ($signed(Hori + h_r) < $signed(0)) || ($signed(Hori + h_r) >= $signed(H))
                            || ($signed(Wori + w_r) < $signed(0)) || ($signed(Wori + w_r) >= $signed(W));
                    raddr_w = ifaddr + (Iori + i_r) * H * W + Hori_plus_h * W + Wori_plus_w;
                    w_w = (w_r == Wext - 1) ? 0 : w_r + 1;
                    h_w = (w_r == Wext - 1) ? ((h_r == (Hext - 1)) ? 0 : h_r + 1) : h_r;
                    i_w = ((w_r == Wext - 1) && (h_r == (Hext - 1))) ? i_r + 1 : i_r;
                    cnt_w = 1;
                    state_next = S_LIF;
                end
                else if (store_output && pe_idle) begin
                    state_next = S_SOF;
                end
            end
            S_LW: begin
                if (rready) begin
                    rvalid_w = 1'b1;
                    raddr_w = weaddr + Oori * I * K * K + cnt_r;
                    cnt_w = cnt_r + 1;
                    if (cnt_r == Oext * I * K * K) begin
                        if (has_bias) begin
                            raddr_w = weaddr + O * I * K * K + Oori;
                            cnt_w = 1;
                            state_next = S_LB;
                        end
                        else begin
                            rvalid_w = 1'b0;
                            state_next = S_DONE;
                        end
                    end
                end
            end
            S_LB: begin
                if (rready) begin
                    rvalid_w = 1'b1;
                    raddr_w = weaddr + O * I * K * K + (Oori + cnt_r);
                    cnt_w = cnt_r + 1;
                    if (cnt_r == Oext) begin
                        rvalid_w = 1'b0;
                        state_next = S_DONE;
                    end
                end
            end
            S_LIF: begin
                if (rready) begin
                    rvalid_w = 1'b1;
                    is_pad_w = ($signed(Hori + h_r) < $signed(0)) || ($signed(Hori + h_r) >= $signed(H))
                            || ($signed(Wori + w_r) < $signed(0)) || ($signed(Wori + w_r) >= $signed(W));
                    raddr_w = ifaddr + (Iori + i_r) * H * W + Hori_plus_h * W + Wori_plus_w;
                    w_w = (w_r == Wext - 1) ? 0 : w_r + 1;
                    h_w = (w_r == Wext - 1) ? ((h_r == (Hext - 1)) ? 0 : h_r + 1) : h_r;
                    i_w = ((w_r == Wext - 1) && (h_r == (Hext - 1))) ? i_r + 1 : i_r;
                    cnt_w = cnt_r + 1;
                    if (cnt_r == Iext * Hext * Wext) begin
                        rvalid_w = 1'b0;
                        state_next = S_DONE;
                    end
                end
            end
            S_SOF: begin
                if (cnt_r == Oext * Hout * Wout) begin
                    state_next = S_DONE;
                end
                else begin
                    if (~waiting_r) begin
                        if (pe_dout_valid) begin
                            wvalid_w = 1'b1;
                            waddr_w = ofaddr + (Oori + o_r) * (H - K + 1 + 2*pad) * (W - K + 1 + 2*pad) 
                                    + Hori_plus_h_plus_pad * (W - K + 1 + 2*pad) + Wori_plus_w_plus_pad;
                            w_w = (w_r == Wout - 1) ? 0 : w_r + 1;
                            h_w = (w_r == Wout - 1) ? ((h_r == (Hout - 1)) ? 0 : h_r + 1) : h_r;
                            o_w = ((w_r == Wout - 1) && (h_r == (Hout - 1))) ? o_r + 1 : o_r;
                            wdata_w = {16'b0, pe_dout_data};
                            waiting_w = 1;
                        end
                    end
                    else if (wready) begin
                        wvalid_w = 1'b0;
                        cnt_w = cnt_r + 1;
                        pe_dout_ready_w = 1'b1;
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
        if(rst) begin
            cnt_r <= 0;
            waddr_r <= 0;
            raddr_r <= 0;
            wvalid_r <= 0;
            rvalid_r <= 0;
            wdata_r <= 0;
            waiting_r <= 0;
            pe_dout_ready_r <= 0;
            h_r <= 0;
            w_r <= 0;
            o_r <= 0;
            i_r <= 0;
            is_pad_r <= 0;
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
            pe_dout_ready_r <= pe_dout_ready_w;
            h_r <= h_w;
            w_r <= w_w;
            o_r <= o_w;
            i_r <= i_w;
            is_pad_r <= is_pad_w;
            state <= state_next;
        end
    end
endmodule
