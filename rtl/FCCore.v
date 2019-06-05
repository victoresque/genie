module FCCore (
    input         clk,
    input         rst,
    input  [11:0] cin,
    input  [11:0] cout,
    input         has_bias,
    input         din_valid,
    input  [15:0] din_data,
    output        dout_valid,
    input         dout_ready,
    output [15:0] dout_data
);
    reg [2:0] state, state_next;
    parameter S_READ_INPUT = 0;
    parameter S_READ_WEIGHT = 1;
    parameter S_READ_BIAS = 2;
    parameter S_WRITE_OUTPUT = 3;

    reg [31:0] cnt_r, cnt_w;
    reg        dout_valid_r, dout_valid_w;
    reg [15:0] dout_data_r, dout_data_w;

    reg  [9:0] psum_id_r, psum_id_w;

    reg   [9:0] if_addr_r, if_addr_w;
    reg  [31:0] if_wdata_r, if_wdata_w;
    reg         if_wvalid_r, if_wvalid_w;
    wire [31:0] if_rdata;
    reg   [9:0] of_addr_r, of_addr_w;
    reg  [31:0] of_wdata_r, of_wdata_w;
    reg         of_wvalid_r, of_wvalid_w;
    wire [31:0] of_rdata;

    sram4K sram_if_bias (
        .clk(clk),
        .addr(if_addr_r),
        .wdata(if_wdata_r),
        .wen(if_wvalid_r),
        .rdata(if_rdata)
    );

    sram4K sram_of (
        .clk(clk),
        .addr(of_addr_r),
        .wdata(of_wdata_r),
        .wen(of_wvalid_r),
        .rdata(of_rdata)
    );

    assign dout_valid = dout_valid_r;

    wire [15:0] sum = $signed(if_rdata[15:0]) + $signed(of_rdata[15:0]);
    assign dout_data = sum[15] ? 0 : {16'b0, sum};


    reg  [31:0] MULT;

    integer i;

    always @ (*) begin
        cnt_w = cnt_r;
        psum_id_w = psum_id_r;
        dout_valid_w = dout_valid_r;
        dout_data_w = dout_data_r;
        if_addr_w = if_addr_r;
        if_wdata_w = if_wdata_r;
        if_wvalid_w = 1'b0;
        of_addr_w = of_addr_r;
        of_wdata_w = of_wdata_r;
        of_wvalid_w = 1'b0;
        state_next = state;

        case(state)
            S_READ_INPUT: begin
                if (if_wvalid_r) begin
                    if_addr_w = if_addr_r + 1;
                end

                if (cnt_r == cin) begin
                    cnt_w = 0;
                    if_addr_w = 0;
                    of_addr_w = -1;
                    of_wdata_w = 0;
                    state_next = S_READ_WEIGHT;
                end
                else if (din_valid) begin
                    cnt_w = cnt_r + 1;
                    if_wvalid_w = 1'b1;
                    if_wdata_w = din_data;
                end
            end
            S_READ_WEIGHT: begin
                if (cnt_r == cin * cout) begin
                    cnt_w = 0;
                    if_addr_w = -1;
                    state_next = S_READ_BIAS;
                end
                else if (din_valid) begin
                    if (if_addr_r == cin - 1) begin
                        if_addr_w = 0;
                        of_addr_w = of_addr_r + 1;
                        of_wvalid_w = 1'b1;
                    end
                    else begin
                        if_addr_w = if_addr_r + 1;
                    end

                    MULT = $signed(if_rdata[15:0]) * $signed(din_data);
                    if (if_addr_r == 0) begin
                        of_wdata_w = MULT[25:10];
                    end
                    else begin
                        of_wdata_w = $signed(of_wdata_r) + $signed(MULT[25:10]);
                    end
                    cnt_w = cnt_r + 1;
                end
            end
            S_READ_BIAS: begin
                if (cnt_r == cout) begin
                    cnt_w = 0;
                    if_addr_w = 0;
                    of_addr_w = 0;
                    state_next = S_WRITE_OUTPUT;
                end
                else if (din_valid) begin
                    if_wvalid_w = 1'b1;
                    if_addr_w = if_addr_r + 1;
                    if_wdata_w = din_data;
                    cnt_w = cnt_r + 1;
                end
            end
            S_WRITE_OUTPUT: begin
                dout_valid_w = 1'b1;
                if (dout_ready) begin
                    if_addr_w = if_addr_r + 1;
                    of_addr_w = of_addr_r + 1;
                end
            end
        endcase
    end

    always @ (posedge clk) begin
        if (rst) begin
            cnt_r <= 0;
            psum_id_r <= 0;
            dout_valid_r <= 0;
            dout_data_r <= 0;
            if_addr_r <= 0;
            if_wdata_r <= 0;
            if_wvalid_r <= 0;
            of_addr_r <= 0;
            of_wdata_r <= 0;
            of_wvalid_r <= 0;
            state <= S_READ_INPUT;
        end
        else begin
            cnt_r <= cnt_w;
            psum_id_r <= psum_id_w;
            dout_valid_r <= dout_valid_w;
            dout_data_r <= dout_data_w;
            if_addr_r <= if_addr_w;
            if_wdata_r <= if_wdata_w;
            if_wvalid_r <= if_wvalid_w;
            of_addr_r <= of_addr_w;
            of_wdata_r <= of_wdata_w;
            of_wvalid_r <= of_wvalid_w;
            state <= state_next;
        end
    end
endmodule
