/*******************************************************
* Advanced Digital IC Design                          *
*                                                     *
* Final Project: ADPLL                                *
*******************************************************/
//
// NOTE ON THIS FILE'S SYNTAX BUG:
// The baseline TOP.v begins with a banner comment that is missing its
// opening "/*" (it starts directly with a line of asterisks). That is
// a hard syntax error under IEEE-1364 Verilog -- confirmed by
// compiling the original file with Icarus Verilog, which rejects it
// immediately. Fixed here by adding the missing comment opener; no
// other change was made to this file.

`timescale 1ns/1ps
`include "ADPLL.v"
`include "TEST.v"

module TOP;

    // NEW (LP-GS-ADPLL): explicit declarations for the multi-bit debug
    // signal (implicit nets default to 1 bit wide and would silently
    // truncate DUTY_COUNT).
    wire       GEAR_SEL;
    wire       COMPARE_ENABLE;
    wire [3:0] DUTY_COUNT;

    ADPLL ADPLL(
        .REF_CLK(REF_CLK),
        .RESET(RESET),
        .M2(M2),
        .M1(M1),
        .M0(M0),
        .LOCK(LOCK),
        .OUT_CLK(OUT_CLK),
        .GEAR_SEL(GEAR_SEL),
        .COMPARE_ENABLE(COMPARE_ENABLE),
        .DUTY_COUNT(DUTY_COUNT)
    );

    TEST TEST(
        .REF_CLK(REF_CLK),
        .RESET(RESET),
        .M2(M2),
        .M1(M1),
        .M0(M0),
        .LOCK(LOCK),
        .OUT_CLK(OUT_CLK),
        .GEAR_SEL(GEAR_SEL),
        .COMPARE_ENABLE(COMPARE_ENABLE),
        .DUTY_COUNT(DUTY_COUNT)
    );

endmodule
