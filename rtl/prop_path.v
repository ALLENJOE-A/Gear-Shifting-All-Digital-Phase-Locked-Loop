	imescale 1ns/1ps

module prop_path (
    input  wire       clk,
    input  wire       reset,
    input  wire       enable,
    input  wire       p_up,
    input  wire       p_down,
    input  wire [3:0] threshold,
    output reg        nudge_up,
    output reg        nudge_down
);

    reg [3:0] cnt_up, cnt_down;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt_up     <= 4'd0;
            cnt_down   <= 4'd0;
            nudge_up   <= 1'b0;
            nudge_down <= 1'b0;
        end else if (enable) begin
            nudge_up   <= (cnt_up   >= threshold);
            nudge_down <= (cnt_down >= threshold);
            if (p_up) cnt_up <= cnt_up + 1'b1; else cnt_up <= 4'd0;
            if (p_down) cnt_down <= cnt_down + 1'b1; else cnt_down <= 4'd0;
        end else begin
            nudge_up   <= 1'b0;
            nudge_down <= 1'b0;
        end
    end

endmodule
