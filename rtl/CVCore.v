module BehavCVCore (
    input         clk,
    input         rst,
    input         din_valid,
    input  [15:0] din_data,
    output        dout_valid,
    input         dout_ready,
    output [15:0] dout_data,
    input         has_bias,

    input         load_weight,
    input         load_input,
    input         store_output,
    output        calc_done,

    input   [4:0] K,
    input  [10:0] Iext,
    input  [10:0] Oext,
    input   [7:0] Hext,
    input   [7:0] Wext
);
    reg        dout_valid;
    reg [15:0] dout_data;
    reg        calc_done;

    reg        waiting;

    reg  [3:0] state, state_next;
    parameter S_IDLE        = 0;
    parameter S_READ_WEIGHT = 1;
    parameter S_READ_INPUT  = 2;
    parameter S_READ_BIAS   = 3;
    parameter S_CALC        = 4;
    parameter S_OUTPUT      = 5;
    parameter S_DONE1       = 6;
    parameter S_DONE2       = 7;
    
    reg  [15:0] ifmap[0:32768];
    reg  [15:0] weight[0:32768];
    reg  [15:0] psum[0:32768];
    reg  [15:0] bias[0:1023];

    reg is_first_iblock;
    integer idx, h, w, i, o, addr, sum, ifidx;

    always @ (*) begin  
        sum = 0;
        for (ifidx = 0; ifidx < Iext; ifidx = ifidx + 1) begin
            sum = $signed(sum)
                + $signed(ifmap[ifidx * Hext * Wext + (h-1) * Wext + (w-1)]) 
                          * $signed(weight[o * Iext * K * K + ifidx * K * K + 0 * K + 0])
                + $signed(ifmap[ifidx * Hext * Wext + (h-0) * Wext + (w-1)]) 
                          * $signed(weight[o * Iext * K * K + ifidx * K * K + 1 * K + 0])
                + $signed(ifmap[ifidx * Hext * Wext + (h+1) * Wext + (w-1)]) 
                          * $signed(weight[o * Iext * K * K + ifidx * K * K + 2 * K + 0])
                + $signed(ifmap[ifidx * Hext * Wext + (h-1) * Wext + (w-0)]) 
                          * $signed(weight[o * Iext * K * K + ifidx * K * K + 0 * K + 1])
                + $signed(ifmap[ifidx * Hext * Wext + (h-0) * Wext + (w-0)]) 
                          * $signed(weight[o * Iext * K * K + ifidx * K * K + 1 * K + 1])
                + $signed(ifmap[ifidx * Hext * Wext + (h+1) * Wext + (w-0)]) 
                          * $signed(weight[o * Iext * K * K + ifidx * K * K + 2 * K + 1])
                + $signed(ifmap[ifidx * Hext * Wext + (h-1) * Wext + (w+1)]) 
                          * $signed(weight[o * Iext * K * K + ifidx * K * K + 0 * K + 2])
                + $signed(ifmap[ifidx * Hext * Wext + (h-0) * Wext + (w+1)]) 
                          * $signed(weight[o * Iext * K * K + ifidx * K * K + 1 * K + 2])
                + $signed(ifmap[ifidx * Hext * Wext + (h+1) * Wext + (w+1)]) 
                          * $signed(weight[o * Iext * K * K + ifidx * K * K + 2 * K + 2]);
            if (has_bias) begin
                sum = $signed(sum) + $signed(bias[o]);
            end
        end
    end

    always @ (posedge clk) begin
        if (rst) begin
            for (idx = 0; idx < Iext * Hext * Wext; idx = idx + 1) ifmap[idx] <= 32'bx;
            for (idx = 0; idx < Oext * Iext * K * K; idx = idx + 1) weight[idx] <= 32'bx;
            for (idx = 0; idx < Oext * (Hext - K + 1) * (Wext - K + 1); idx = idx + 1) psum[idx] <= 32'bx;
            addr <= 0;
            calc_done <= 0;
            dout_valid <= 0;
            state <= S_IDLE;
        end
        else begin
            case(state)
                S_IDLE: begin
                    dout_valid <= 0;
                    if (load_weight) begin
                        state <= S_READ_WEIGHT;
                    end
                    else if (load_input) begin
                        state <= S_READ_INPUT;
                    end
                    else if (store_output) begin
                        state <= S_OUTPUT;
                    end
                end
                S_READ_WEIGHT: begin
                    if (din_valid) begin
                        weight[addr] <= din_data;
                        if (addr == Oext * Iext * K * K - 1) begin
                            is_first_iblock <= 1;
                            addr <= 0;
                            h <= 1;
                            w <= 1;
                            i <= 0;
                            o <= 0;
                            if (has_bias) begin
                                state <= S_READ_BIAS;
                            end
                            else begin
                                state <= S_DONE1;
                            end
                        end
                        else begin
                            addr <= addr + 1;
                        end
                    end
                end
                S_READ_BIAS: begin
                    if (din_valid) begin
                        bias[addr] <= din_data;
                        if (addr == Oext - 1) begin
                            addr <= 0;
                            state <= S_READ_INPUT;
                        end
                        else begin
                            addr <= addr + 1;
                        end
                    end
                end
                S_READ_INPUT: begin
                    if (din_valid) begin
                        ifmap[addr] <= din_data;
                        if (addr == Iext * Hext * Wext - 1) begin
                            addr <= 0;
                            state <= S_CALC;
                        end
                        else begin
                            addr <= addr + 1;
                        end
                    end
                end
                S_CALC: begin
                    psum[addr] <= sum[25:10];

                    w <= (w == (Wext - K + 1)) ? 1 : w + 1;
                    h <= (w == (Wext - K + 1)) ? ((h == (Hext - K + 1)) ? 1 : h + 1) : h;
                    o <= (w == (Wext - K + 1) && h == (Hext - K + 1)) ? o + 1 : o;

                    if (addr == Oext * (Hext - K + 1) * (Wext - K + 1) - 1) begin
                        addr <= 0;
                        calc_done <= 1;
                        i <= 0;
                        o <= 0;
                        state <= S_DONE1;
                    end
                    else begin
                        addr <= addr + 1;
                    end
                end
                S_OUTPUT: begin
                    dout_valid <= 1;
                    dout_data <= psum[addr][15] ? 0 : psum[addr];

                    // perform ReLU here
                    if (has_bias) begin    
                        if (i == (Hext - K + 1) * (Wext - K + 1) - 1) begin
                            o <= 0;
                            i <= 0;
                        end
                        else begin
                            i <= i + 1;
                        end
                    end

                    calc_done <= 0;
                    if (dout_ready) begin
                        if (addr == Oext * (Hext - K + 1) * (Wext - K + 1) - 1) begin
                            addr <= 0;
                            state <= S_DONE1;
                        end
                        else begin
                            addr <= addr + 1;
                        end
                    end
                end
                S_DONE1: begin
                    state <= S_DONE2;
                end
                S_DONE2: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end
endmodule
