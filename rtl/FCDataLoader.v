module FCDataLoader (
    input         clk,
    input         rst,

    input  [11:0] cin,
    input  [11:0] cout,
    input         has_bias,
    input   [4:0] act_type,

    input         lif_start,
    input         lw_start,
    input         sof_start,

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
    parameter S_IDLE = 0;
    parameter S_LIF  = 1;
    parameter S_LW   = 2;
    parameter S_LB   = 3;
    parameter S_SOF  = 4;
    parameter S_DONE = 5;

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

    wire        fc_dout_valid;
    wire [15:0] fc_dout_data;
    reg         fc_dout_ready_r, fc_dout_ready_w;

    FCCore u_FCCore (
        .clk(clk),
        .rst(rst),
        .cin(cin),
        .cout(cout),
        .has_bias(has_bias),
        .act_type(act_type),
        .din_valid(rready),
        .din_data(rdata[15:0]),
        .dout_valid(fc_dout_valid),
        .dout_ready(fc_dout_ready_r),
        .dout_data(fc_dout_data)
    );

    reg  [23:0] total_weight_r;
    wire [23:0] total_weight_w;
    assign total_weight_w = cin * cout;

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
            rvalid_w = 1'b0;
            wvalid_w = 1'b0;
            waiting_w = 0;
            cnt_w = 0;
            if (lif_start) begin
                rvalid_w = 1'b1;
                raddr_w = base_addr;
                cnt_w = 1;
                state_next = S_LIF;
            end
            else if (lw_start) begin
                rvalid_w = 1'b1;
                raddr_w = base_addr;
                cnt_w = 1;
                state_next = S_LW;
            end
            else if (sof_start) begin
                state_next = S_SOF;
            end
        end
        S_LIF: begin
            if (rready) begin
                rvalid_w = 1'b1;
                raddr_w = base_addr + cnt_r;
                cnt_w = cnt_r + 1;
                if (cnt_r == cin) begin
                    rvalid_w = 1'b0;
                    state_next = S_DONE;
                end
            end
        end
        S_LW: begin
            if (rready) begin
                rvalid_w = 1'b1;
                raddr_w = base_addr + cnt_r;
                cnt_w = cnt_r + 1;
                if (cnt_r == total_weight_r) begin
                    if (has_bias) begin
                        raddr_w = base_addr + total_weight_r;
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
                raddr_w = base_addr + total_weight_r + cnt_r;
                cnt_w = cnt_r + 1;
                if (cnt_r == cout) begin
                    rvalid_w = 1'b0;
                    state_next = S_DONE;
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
