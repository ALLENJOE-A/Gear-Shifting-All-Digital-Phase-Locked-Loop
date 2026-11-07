	imescale 1ns/1ps

module lock_det #(
    parameter N_CONFIRM = 8
)(
    input  wire ref_clk,
    input  wire reset,
    input  wire freq_lock_raw,
    output reg  lock_confirmed,
    output reg [3:0] confirm_count
);

    always @(posedge ref_clk or posedge reset) begin
        if (reset) begin
            lock_confirmed <= 1'b0;
            confirm_count  <= 4'd0;
        end else begin
            if (freq_lock_raw) begin
                if (confirm_count < N_CONFIRM)
                    confirm_count <= confirm_count + 1'b1;
                else
                    lock_confirmed <= 1'b1;
            end else begin
                confirm_count  <= 4'd0;
                lock_confirmed <= 1'b0;
            end
        end
    end

endmodule
