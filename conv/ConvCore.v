module BehavConvCore (
    input         clk,
    input         rst_n,
    input   [4:0] Hp,
    input   [4:0] Wp,
    input   [7:0] I,
    input   [7:0] O,
    input   [2:0] K,
    input         din_valid,
    input  [15:0] din_data,
    output        dout_valid,
    input         dout_ready,
    output [15:0] dout_data
);
    reg        dout_valid;
    reg [15:0] dout_data;

    reg  [3:0] state, state_next;
    parameter S_READ_INPUT = 0;
    parameter S_READ_WEIGHT = 1;
    parameter S_CALC = 2;
    parameter S_OUTPUT = 3;

    // sram_4K IF_bank0 ();
    // sram_4K IF_bank1 ();
    // sram_4K IF_bank2 ();
    // sram_4K IF_bank3 ();
    // sram_4K IF_bank4 ();
    // sram_4K IF_bank5 ();
    // sram_4K IF_bank6 ();
    // sram_4K IF_bank7 ();
    // sram_4K IF_bank8 ();
    // sram_4K IF_bank9 ();
    // sram_4K IF_bank10 ();
    // sram_4K IF_bank11 ();
    
    reg  [15:0] ifmap[0:1727];
    reg  [15:0] weight[0:1295];
    reg  [15:0] ofmap[0:1199];

    integer idx;
    integer h, w, i, o;
    integer addr;
    integer sum;

    integer ifidx;

    // always @ (*) begin
    //     case(state)
    //         S_READ_INPUT: begin
    //         end
    //         S_READ_WEIGHT: begin
    //         end
    //         S_CALC: begin
    //         end
    //         S_OUTPUT: begin
    //         end
    //     endcase
    // end

    always @ (*) begin  
        sum = 0;
        for (ifidx = 0; ifidx < 12; ifidx = ifidx + 1) begin
            sum = $signed(sum)
                    + $signed(ifmap[ifidx * 144 + (h-1) * 12 + (w-1)]) * $signed(weight[o * 108 + ifidx * 9 + 0 * 3 + 0])
                    + $signed(ifmap[ifidx * 144 + (h-0) * 12 + (w-1)]) * $signed(weight[o * 108 + ifidx * 9 + 1 * 3 + 0])
                    + $signed(ifmap[ifidx * 144 + (h+1) * 12 + (w-1)]) * $signed(weight[o * 108 + ifidx * 9 + 2 * 3 + 0])
                    + $signed(ifmap[ifidx * 144 + (h-1) * 12 + (w-0)]) * $signed(weight[o * 108 + ifidx * 9 + 0 * 3 + 1])
                    + $signed(ifmap[ifidx * 144 + (h-0) * 12 + (w-0)]) * $signed(weight[o * 108 + ifidx * 9 + 1 * 3 + 1])
                    + $signed(ifmap[ifidx * 144 + (h+1) * 12 + (w-0)]) * $signed(weight[o * 108 + ifidx * 9 + 2 * 3 + 1])
                    + $signed(ifmap[ifidx * 144 + (h-1) * 12 + (w+1)]) * $signed(weight[o * 108 + ifidx * 9 + 0 * 3 + 2])
                    + $signed(ifmap[ifidx * 144 + (h-0) * 12 + (w+1)]) * $signed(weight[o * 108 + ifidx * 9 + 1 * 3 + 2])
                    + $signed(ifmap[ifidx * 144 + (h+1) * 12 + (w+1)]) * $signed(weight[o * 108 + ifidx * 9 + 2 * 3 + 2]);
        end
    end

    always @ (posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (idx = 0; idx < 1728; idx = idx + 1) ifmap[idx] <= 0;
            for (idx = 0; idx < 1296; idx = idx + 1) weight[idx] <= 0;
            for (idx = 0; idx < 1200; idx = idx + 1) ofmap[idx] <= 0;
            addr <= 0;
            state <= S_READ_INPUT;
        end
        else begin
            case(state)
                S_READ_INPUT: begin
                    if (din_valid) begin
                        ifmap[addr] <= din_data;
                        if (addr == 1727) begin
                            addr <= 0;
                            state <= S_READ_WEIGHT;
                        end
                        else begin
                            addr <= addr + 1;
                        end
                    end
                end
                S_READ_WEIGHT: begin
                    if (din_valid) begin
                        weight[addr] <= din_data;
                        if (addr == 1295) begin
                            addr <= 0;
                            h <= 1;
                            w <= 1;
                            i <= 0;
                            o <= 0;

                            state <= S_CALC;
                        end
                        else begin
                            addr <= addr + 1;
                        end
                    end
                end
                S_CALC: begin
                    // IF: addr = i * 144 + h * 12 + w;
                    //  W: addr = o * 108 + i * 9 + ki * 3 + kj;
                    ofmap[addr] <= sum[25:10];

                    w <= (w == 10) ? 1 : w + 1;
                    h <= (w == 10) ? ((h == 10) ? 1 : h + 1) : h;
                    o <= (w == 10 && h == 10) ? o + 1 : o;

                    if (addr == 1199) begin
                        addr <= 0;
                        state <= S_OUTPUT;
                    end
                    else begin
                        addr <= addr + 1;
                    end
                end
                S_OUTPUT: begin
                    dout_valid <= 1;
                    dout_data <= ofmap[addr];
                    addr <= addr + 1;
                end
            endcase
        end
    end
endmodule
