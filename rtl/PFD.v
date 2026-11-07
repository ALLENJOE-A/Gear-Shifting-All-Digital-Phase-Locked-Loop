`timescale 1ns/1ps

`ifdef SIM_DELAY
    `define DLY #0.05
`else
    `define DLY
`endif

module PFD(
    input  wire IN,
    input  wire FB,
    output reg  flagu,
    output reg  flagd
);

    reg QU, QD;
    wire CDN;
    wire OUTU, OUTD;
    reg  OUTBU, OUTBD;

    // Prevent 'X' propagation on startup
    initial begin
        QU = 1'b0;
        QD = 1'b0;
        flagu = 1'b0;
        flagd = 1'b0;
        OUTBU = 1'b1;
        OUTBD = 1'b1;
    end

    assign `DLY CDN  = ~(QU & QD);
    assign `DLY OUTU = ~(QU & ~QD);
    assign `DLY OUTD = ~(QD & ~QU);

    always @(*) begin
        OUTBU = OUTU;
        OUTBD = OUTD;
    end

    always @(posedge IN or negedge CDN) begin
        if (!CDN) QU <= 1'b0;
        else      QU <= 1'b1;
    end

    always @(posedge FB or negedge CDN) begin
        if (!CDN) QD <= 1'b0;
        else      QD <= 1'b1;
    end

    always @(posedge IN or negedge OUTBU) begin
        if (!OUTBU) flagu <= 1'b0;
        else        flagu <= 1'b1;
    end

    always @(posedge FB or negedge OUTBD) begin
        if (!OUTBD) flagd <= 1'b0;
        else        flagd <= 1'b1;
    end

endmodule
