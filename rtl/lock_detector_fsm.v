// =====================================================================
// lock_detector_fsm.v -- NEW block, LP-GS-ADPLL project
//
// This is the project's core novelty block: a single lock-state FSM
// that jointly drives two independent power/performance knobs off one
// lock-detector signal (freq_lock from CONTROLLER.v), instead of two
// separately-tuned subsystems:
//
//   Mechanism 1 -- Gear-Shifting Loop Filter (performance):
//     gear_sel = 0 (Gear 1)  : acquisition, and the first N_CONFIRM
//                              reference cycles immediately after lock
//                              is first asserted. FILTER.v uses its
//                              wider-bandwidth threshold here -- same
//                              response as the unmodified baseline.
//     gear_sel = 1 (Gear 2)  : entered once lock has been continuously
//                              asserted for N_CONFIRM cycles. FILTER.v
//                              switches to a narrower-bandwidth
//                              threshold, trading a little settling
//                              speed for lower steady-state
//                              (tracking) jitter.
//
//   Mechanism 2 -- Duty-Cycled Comparison (power):
//     While in Gear 2, compare_enable is asserted only 1-in-DUTY_K
//     reference cycles. On the other (DUTY_K-1) cycles it is held low,
//     which FILTER.v uses to freeze its counters and DCO code register
//     (no update, no toggling) -- the primary power-saving mechanism,
//     since the design spends the large majority of its operating life
//     in the locked/tracking state. Gear 1 (including all of
//     acquisition) always runs at full rate (compare_enable = 1) so
//     lock-in time is unaffected.
//
// If freq_lock ever de-asserts while in Gear 2 (e.g. a reference
// frequency step pushes the loop out of lock), the FSM immediately
// falls back to Gear 1 / full-rate comparison so re-acquisition is not
// slowed down by duty-cycling.
//
// Both N_CONFIRM and DUTY_K are exposed as parameters so the gear x K
// design space described in the project report can be swept without
// editing the RTL body.
//
// Fully synthesizable: single clock domain (negedge ref_clk), single
// asynchronous reset (posedge reset), all outputs are registered and
// assigned on every path of every state (no inferred latches).
// =====================================================================

`timescale 1ns/1ps

module lock_detector_fsm #(
    parameter N_CONFIRM = 16,  // ref_clk cycles of continuous lock required before switching Gear1 -> Gear2
    parameter DUTY_K    = 4    // duty-cycle factor in Gear 2: compare_enable asserted 1-in-DUTY_K cycles
)(
    input  wire       ref_clk,
    input  wire       reset,
    input  wire       freq_lock,        // from CONTROLLER: asserted once binary-search step size == 1
    output reg        gear_sel,         // 0 = Gear 1 (wide bandwidth), 1 = Gear 2 (narrow bandwidth, duty-cycled)
    output reg        compare_enable,   // 1 = FILTER may update this cycle, 0 = held (power-saving gate)
    output reg [3:0]  duty_count        // debug/observability: position within the current duty-cycle window
);

    localparam S_ACQUIRE = 1'b0;  // Gear 1: unlocked, or locked but not yet confirmed stable
    localparam S_TRACK   = 1'b1;  // Gear 2: locked and stable for N_CONFIRM cycles -- narrow band + duty-cycled

    reg       state;
    reg [7:0] stable_count;

    always @(negedge ref_clk or posedge reset) begin
        if (reset) begin
            state          <= S_ACQUIRE;
            stable_count   <= 8'd0;
            duty_count     <= 4'd0;
            gear_sel       <= 1'b0;
            compare_enable <= 1'b1;
        end else begin
            case (state)

                S_ACQUIRE: begin
                    gear_sel       <= 1'b0;
                    compare_enable <= 1'b1;  // full-rate comparison -- fast lock, matches baseline behavior
                    duty_count     <= 4'd0;
                    if (freq_lock) begin
                        if (stable_count >= (N_CONFIRM - 1)) begin
                            state        <= S_TRACK;
                            stable_count <= 8'd0;
                        end else begin
                            state        <= S_ACQUIRE;
                            stable_count <= stable_count + 8'd1;
                        end
                    end else begin
                        state        <= S_ACQUIRE;
                        stable_count <= 8'd0;
                    end
                end

                S_TRACK: begin
                    stable_count <= 8'd0;
                    if (!freq_lock) begin
                        // Lock lost -- fall back to full-rate, wide-bandwidth acquisition immediately
                        state          <= S_ACQUIRE;
                        gear_sel       <= 1'b0;
                        compare_enable <= 1'b1;
                        duty_count     <= 4'd0;
                    end else begin
                        state    <= S_TRACK;
                        gear_sel <= 1'b1;
                        if (duty_count >= (DUTY_K - 1)) begin
                            duty_count     <= 4'd0;
                            compare_enable <= 1'b1;   // the 1-in-K enabled cycle
                        end else begin
                            duty_count     <= duty_count + 4'd1;
                            compare_enable <= 1'b0;   // held cycle -- power saving
                        end
                    end
                end

                default: begin
                    state          <= S_ACQUIRE;
                    stable_count   <= 8'd0;
                    duty_count     <= 4'd0;
                    gear_sel       <= 1'b0;
                    compare_enable <= 1'b1;
                end
            endcase
        end
    end

endmodule
