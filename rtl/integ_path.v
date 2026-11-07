	imescale 1ns/1ps

module integ_path (
    input  wire         clk,
    input  wire         reset,
    input  wire         enable,
    input  wire         nudge_up,
    input  wire         nudge_down,
    output reg  [128:0] dco_tuning_code
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            dco_tuning_code <= {129{1'b0}};
        end else if (enable) begin
            if (nudge_up && ~dco_tuning_code[128])
                dco_tuning_code <= {dco_tuning_code[127:0], 1'b1};
            else if (nudge_down && dco_tuning_code[0])
                dco_tuning_code <= {1'b0, dco_tuning_code[128:1]};
        end
    end

endmodule
