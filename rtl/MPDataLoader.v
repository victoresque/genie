module MPDataLoader (
    input         clk,
    input         rst,
    input  [10:0] C,
    input  [10:0] H,
    input  [10:0] W,
    input  [26:0] ifaddr,
    input  [26:0] ofaddr,

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
    parameter S_IDLE = 0;
    parameter S_LIF  = 1;
    parameter S_SOF  = 2;
    parameter S_DONE = 3;

    reg  [25:0] waddr_r, waddr_w;
    reg  [25:0] raddr_r, raddr_w;
    reg         wvalid_r, wvalid_w;
    reg         rvalid_r, rvalid_w;
    reg  [31:0] wdata_r, wdata_w;
    reg         waiting_r, waiting_w;
    reg  [31:0] cnt_r, cnt_w;

    reg   [7:0] h_w, h_r;
    reg   [7:0] w_w, w_r;
    reg  [10:0] c_w, c_r;
    reg   [2:0] mpid_w, mpid_r;

    assign waddr = waddr_r;
    assign raddr = raddr_r;
    assign wvalid = wvalid_r;
    assign rvalid = rvalid_r;
    assign wdata = wdata_r;
    assign done = state == S_DONE;

    wire [10:0] Hcrop;
    wire [10:0] Wcrop;
    assign Hcrop = {H[10:1], 1'b0};
    assign Wcrop = {W[10:1], 1'b0};

    reg  [15:0] max_r, max_w;

    always @ (*) begin
        cnt_w = cnt_r;
        waddr_w = waddr_r;
        raddr_w = raddr_r;
        wvalid_w = wvalid_r;
        rvalid_w = rvalid_r;
        wdata_w = wdata_r;
        waiting_w = waiting_r;
        h_w = h_r;
        w_w = w_r;
        c_w = c_r;
        max_w = max_r;
        mpid_w = mpid_r;
        state_next = state;

        case(state)
            S_IDLE: begin
                state_next = S_LIF;
                waiting_w = 0;
                mpid_w = 0;
            end
            S_LIF: begin
                if (~waiting_r) begin
                    rvalid_w = 1'b1;
                    raddr_w = ifaddr + c_r * H * W + h_r * W + w_r;

                    w_w = w_r[0] ? w_r - 1 : w_r + 1;
                    h_w = w_r[0] ? h_r + 1 : h_r;
                    mpid_w = mpid_r + 1;

                    waiting_w = 1;
                end
                else if (rready) begin
                    if ($signed(rdata[15:0]) > $signed(max_r)) begin
                        max_w = rdata;
                    end

                    if (mpid_r == 4) begin
                        mpid_w = 0;
                        state_next = S_SOF;
                    end
                    rvalid_w = 1'b0;
                    waiting_w = 0;
                end
            end
            S_SOF: begin
                if (~waiting_r) begin
                    wvalid_w = 1'b1;
                    waddr_w = ofaddr + c_r * (Hcrop / 2) * (Wcrop / 2) + (h_r / 2 - 1) * (Wcrop / 2) + (w_r / 2);
                    w_w = (w_r == Wcrop - 2) ? 0 : w_r + 2;
                    h_w = (w_r == Wcrop - 2) ? ((h_r == Hcrop) ? 0 : h_r) : h_r - 2;
                    c_w = ((w_r == Wcrop - 2) && (h_r == Hcrop )) ? c_r + 1 : c_r;
                    wdata_w = {16'b0, max_r};
                    max_w = {1'b1, 15'b0};
                    waiting_w = 1;
                end
                else if (wready) begin
                    wvalid_w = 1'b0;
                    cnt_w = cnt_r + 1;
                    waiting_w = 0;
                    if (cnt_r == C * Hcrop * Wcrop / 4) begin
                        state_next = S_DONE;
                    end
                    else begin
                        state_next = S_LIF;
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
            h_r <= 0;
            w_r <= 0;
            c_r <= 0;
            max_r <= 0;
            mpid_r <= 0;
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
            h_r <= h_w;
            w_r <= w_w;
            c_r <= c_w;
            max_r <= max_w;
            mpid_r <= mpid_w;
            state <= state_next;
        end
    end
endmodule