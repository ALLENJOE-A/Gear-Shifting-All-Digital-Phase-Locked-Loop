//-------------------------------------------------//
//- Advanced Digital IC Design                     //
//-                                                //
//- Exercise: Frequency Divider                    //
//-------------------------------------------------//
//
// =====================================================================
// FREQ_DIV.v -- Synthesizable version
// Source: anlit75/ADPLL, 05_ADPLL/FREQ_DIV.v
//         (N-bit Johnson-counter-based /1..7 programmable divider)
//
// Change made relative to the baseline behavioral file (architecture
// unchanged -- same down-counter, same M-1 comparison, same divide
// range, same purely-combinational decode of out_clk from cnt/M so
// the M==1 pass-through and the timing relative to cnt are identical
// to the source):
//   1. out_clk's combinational always block ended in an else branch of
//      "out_clk = out_clk", i.e. it referenced its own output on a
//      condition (cnt > M-1) that the counter never actually reaches.
//      A combinational block that can hold its previous value infers
//      a level-sensitive latch, which is a standard-cell ASIC design
//      rule violation regardless of whether that branch is reachable
//      in practice. Replaced with an explicit default of 1'b0 for
//      that unreachable case, which removes the latch while producing
//      the same waveform for every value cnt can actually take.
// =====================================================================

`timescale 1ns/1ps

module FREQ_DIV(
    input       reset,
    input       clk,
    input       M2,
    input       M1,
    input       M0,
    output reg  out_clk
);

    reg [2:0] cnt;
    wire [2:0] M = {M2, M1, M0};

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt <= 3'b0;
        end
        else if (cnt > 0) begin
            cnt <= cnt - 1'b1;
        end
        else begin
            cnt <= M - 1;
        end
    end

    always @(*) begin
        if (reset) begin
            out_clk = 1'b0;
        end
        else if (M == 3'b1) begin
            out_clk = clk;
        end
        else if (cnt < M - 1) begin
            out_clk = 1'b0;
        end
        else if (cnt == M - 1) begin
            out_clk = 1'b1;
        end
        else begin
            out_clk = 1'b0;   // cnt > M-1 is unreachable; explicit default avoids a latch
        end
    end

endmodule
