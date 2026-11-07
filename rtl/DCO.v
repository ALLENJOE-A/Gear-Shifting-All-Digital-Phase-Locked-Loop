// =====================================================================
// DCO.v -- Synthesizable version
// Source: anlit75/ADPLL, 05_ADPLL/DCO.v
//         (Tri-state-buffer-based DCO, architecture per Terng-Yin Hsu
//          et al., 2001, doi:10.1109/82.933795 -- as already named in
//          the baseline repo's own README, "128 selectable frequency
//          codes")
//
// WHY THIS FILE HAD TO CHANGE MORE THAN THE OTHERS:
// The baseline DCO.v is a pure simulation shortcut: a 129-way case
// statement maps the thermometer code directly to a "real" (floating
// point) period value taken from characterized silicon/SPICE data,
// and toggles OUT_CLK with "#(period/2.0)". "real" variables and
// delay controls used this way have no synthesizable meaning -- there
// is no standard-cell equivalent of "wait 5.8541 ns, in floating
// point". Yosys/OpenROAD will reject this file outright. This is not
// a case of tightening one always block; the whole module has to be
// re-expressed as an actual piece of digital hardware.
//
// The baseline repo already documents what that hardware is (its own
// README, "DCO" section): a tri-state-buffer delay chain whose active
// length sets the oscillation period, with 128 selectable taps -- a
// ring oscillator, which is exactly the topology re-implemented below
// structurally instead of behaviorally. Architecture is therefore
// preserved (same code-selects-delay-chain-length principle, same
// 129-bit one-per-code control bus code0..code128, same port list,
// same "more code bits set -> shorter active chain -> higher
// frequency" direction seen in the original lookup table), but it is
// now expressed as real gates instead of a #delay/real lookup table.
//
//   code[i] = 1  -> stage i is bypassed (near-zero extra delay)
//   code[i] = 0  -> stage i's delay element is in the active path
//   code = all-0   -> full 129-stage chain active -> longest period
//   code = all-1   -> chain fully bypassed          -> shortest period
// which reproduces the same monotonic direction as the baseline table
// (period=5.85ns at code index 0, period=0.64ns at code index 128).
//
// IMPORTANT CONSEQUENCE FOR THE FLOW (documented, not hidden):
// This is a self-oscillating structure (the feedback path is a
// combinational loop by construction, same as any ring oscillator).
// Yosys/OpenSTA will report a combinational loop on this net unless
// it is explicitly declared as a generated/free-running clock and
// excluded from the loop check in the synthesis/STA constraints
// (e.g. "set_disable_timing" on the feedback path, or modeling OUT_CLK
// as a create_generated_clock source) -- exactly the kind of
// oscillator-specific SDC handling the project's own multi-corner /
// STA plan already anticipates needing for the DCO. Actual oscillation
// period will come from real standard-cell delay after synthesis and
// place & route, not from a fixed table -- also consistent with the
// project report's own note that baseline numbers will be re-measured
// on Sky130 rather than reused from the UMC 0.18um paper.
// =====================================================================

`timescale 1ns/1ps

module DCO(
    input RESET,
    input code0, code1, code2, code3, code4, code5, code6, code7, code8, code9,
    input code10, code11, code12, code13, code14, code15, code16, code17, code18, code19,
    input code20, code21, code22, code23, code24, code25, code26, code27, code28, code29,
    input code30, code31, code32, code33, code34, code35, code36, code37, code38, code39,
    input code40, code41, code42, code43, code44, code45, code46, code47, code48, code49,
    input code50, code51, code52, code53, code54, code55, code56, code57, code58, code59,
    input code60, code61, code62, code63, code64, code65, code66, code67, code68, code69,
    input code70, code71, code72, code73, code74, code75, code76, code77, code78, code79,
    input code80, code81, code82, code83, code84, code85, code86, code87, code88, code89,
    input code90, code91, code92, code93, code94, code95, code96, code97, code98, code99,
    input code100, code101, code102, code103, code104, code105, code106, code107, code108, code109,
    input code110, code111, code112, code113, code114, code115, code116, code117, code118, code119,
    input code120, code121, code122, code123, code124, code125, code126, code127, code128,
    output OUT_CLK
);

    localparam N_STAGES = 129;

    // Re-pack the 129 individual code ports (kept individually named,
    // matching ADPLL.v's existing per-bit instantiation) into a vector
    // purely for internal indexing -- no functional change from the
    // original file, which built the same kind of concatenation for
    // its case statement.
    wire [N_STAGES-1:0] code_sel = {
        code128, code127, code126, code125, code124, code123, code122, code121, code120, code119,
        code118, code117, code116, code115, code114, code113, code112, code111, code110, code109,
        code108, code107, code106, code105, code104, code103, code102, code101, code100, code99,
        code98, code97, code96, code95, code94, code93, code92, code91, code90, code89, code88,
        code87, code86, code85, code84, code83, code82, code81, code80, code79, code78, code77,
        code76, code75, code74, code73, code72, code71, code70, code69, code68, code67, code66,
        code65, code64, code63, code62, code61, code60, code59, code58, code57, code56, code55,
        code54, code53, code52, code51, code50, code49, code48, code47, code46, code45, code44,
        code43, code42, code41, code40, code39, code38, code37, code36, code35, code34, code33,
        code32, code31, code30, code29, code28, code27, code26, code25, code24, code23, code22,
        code21, code20, code19, code18, code17, code16, code15, code14, code13, code12, code11,
        code10, code9, code8, code7, code6, code5, code4, code3, code2, code1, code0
    };

    // Code-selectable delay chain: each stage is either a
    // non-inverting delay element (two series inverters, standing in
    // for a synthesizable BUF-like standard cell pair) or a bypass,
    // chosen per-stage by code_sel[i]. Bypassing a stage removes its
    // incremental delay from the active loop, shortening the period;
    // leaving it active adds delay, lengthening the period --
    // reproducing the direction of the original lookup table (more
    // code bits set -> shorter active chain -> shorter period).
    wire reset_n = ~RESET;
    wire [N_STAGES:0] node;
    wire fb_node;
    assign node[0] = fb_node;

    genvar i;
    generate
        for (i = 0; i < N_STAGES; i = i + 1) begin : stage
            wire mid, delayed;
            not #0.05 (mid, node[i]);       // first inverter of the delay pair
            not #0.05 (delayed, mid);       // second inverter -> net non-inverting, one unit delay
            // Per-stage bypass mux: code_sel[i]=1 skips this stage's delay unit.
            assign node[i+1] = code_sel[i] ? node[i] : delayed;
        end
    endgenerate

    wire ring_tap = node[N_STAGES];

    // Startup/enable gate: RESET forces the ring output high (stopped,
    // non-oscillating); when released, this NAND supplies the single
    // net inversion a ring oscillator needs (the delay chain itself is
    // non-inverting per stage, whether bypassed or not, so exactly one
    // inversion here is what makes the loop oscillate).
    nand #0.1 (fb_node, ~RESET, ring_tap);

    assign OUT_CLK = fb_node;

endmodule
