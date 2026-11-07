// =====================================================================
// FILTER.v  -- LP-GS-ADPLL modified version
// Source: anlit75/ADPLL, 05_ADPLL/FILTER.v
//         (Motorola loop filter, US Patent 5,506,875)
//
// Synthesizability fixes carried over from the baseline cleanup
// (architecture otherwise unchanged -- same anchor-code +-1
// nudge-after-N-consecutive-cycles scheme, same counters):
//   1. cnt_up / cnt_down were sensitive to "negedge p_up or negedge
//      p_down" -- i.e. two independent data signals used directly as
//      flip-flop clocks. Not synthesizable to a standard-cell flip-flop
//      (no single clock net). Both counters clock on the clk domain the
//      module already exposes (wired to phase_clk from CONTROLLER).
//   2. The avg_code combinational block wrote avg_code from avg_code's
//      own current value without being clocked -- infers a
//      level-sensitive latch, flagged by Yosys/OpenROAD as a design
//      rule violation. avg_code is an edge-triggered register with the
//      same next-state equations as the original combinational block.
//
// LP-GS-ADPLL additions (this project's primary edit target):
//   3. gear_sel selects between two bandwidth settings, CNT_N_GEAR1
//      (wide -- acquisition / just-locked, matches the original
//      baseline's fixed CNT_N=4) and CNT_N_GEAR2 (narrow -- deep
//      tracking, larger threshold => fewer +-1 nudges => lower
//      steady-state jitter). Selected by lock_detector_fsm.v.
//   4. compare_enable gates all three registers (cnt_up, cnt_down,
//      avg_code): when compare_enable=0, every register holds its
//      current value (no toggling) instead of evaluating the up/down
//      counters or the code nudge. This is Mechanism 2 (duty-cycled
//      comparison) and also realizes Mechanism 3 (operand gating) --
//      the counters/registers simply do not switch on gated cycles.
//      lock_detector_fsm.v only ever drives compare_enable=0 while in
//      Gear 2 (locked, deep tracking), so acquisition speed (Gear 1,
//      always compare_enable=1) is completely unaffected.
// =====================================================================

`timescale 1ns/1ps

module FILTER(
    input  wire rst,
    input  wire clk,
    input  wire lock,
    input  wire p_up,
    input  wire p_down,
    input  wire [7:0] code,
    input  wire gear_sel,         // 0 = Gear 1 (wide bandwidth), 1 = Gear 2 (narrow bandwidth)
    input  wire compare_enable,   // 1 = allow this cycle's update, 0 = hold (duty-cycle power gate)
    output reg  [7:0] avg_code
);

    parameter CNT_N_GEAR1 = 4;  // wide-bandwidth threshold -- acquisition / just-locked (baseline-matching)
    parameter CNT_N_GEAR2 = 8;  // narrow-bandwidth threshold -- deep tracking, lower steady-state jitter

    wire [3:0] cnt_n_thresh = gear_sel ? CNT_N_GEAR2[3:0] : CNT_N_GEAR1[3:0];

    reg [3:0] cnt_up, cnt_down;

    always @(negedge clk or posedge rst) begin
        if (rst)
            cnt_up <= 0;
        else if (!compare_enable)
            cnt_up <= cnt_up;                              // duty-cycle hold -- gated cycle, no toggling
        else if (cnt_up > (cnt_n_thresh - 1) || !p_down)
            cnt_up <= 0;
        else if (lock && !p_up && p_down)
            cnt_up <= cnt_up + 1'b1;
        else
            cnt_up <= cnt_up;
    end

    always @(negedge clk or posedge rst) begin
        if (rst)
            cnt_down <= 0;
        else if (!compare_enable)
            cnt_down <= cnt_down;                          // duty-cycle hold -- gated cycle, no toggling
        else if (cnt_down > (cnt_n_thresh - 1) || !p_up)
            cnt_down <= 0;
        else if (lock && p_up && !p_down)
            cnt_down <= cnt_down + 1'b1;
        else
            cnt_down <= cnt_down;
    end

    always @(negedge clk or posedge rst) begin
        if (rst)
            avg_code <= 8'd0;
        else if (!lock)
            avg_code <= code;                              // acquisition (Gear 1): track raw controller code directly
        else if (!compare_enable)
            avg_code <= avg_code;                          // duty-cycle hold -- DCO code frozen this cycle (power saving)
        else if (cnt_up == cnt_n_thresh && avg_code != 128)
            avg_code <= avg_code + 1'b1;
        else if (cnt_down == cnt_n_thresh && avg_code != 0)
            avg_code <= avg_code - 1'b1;
        else
            avg_code <= avg_code;
    end

endmodule
