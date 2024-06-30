`default_nettype none
module ksa
    (
        input CLOCK_50,
        input [3:0] KEY,
        input [9:0] SW,
        output [9:0] LEDR,
        input [6:0] HEX0,
        input [6:0] HEX1,
        input [6:0] HEX2,
        input [6:0] HEX3,
        input [6:0] HEX4,
        input [6:0] HEX5
    );

    logic clk, start, reset, finished;
    logic reset_sig;
    assign clk = CLOCK_50;
    assign reset = KEY[0]; //keys are active low
    assign start = KEY[1];
    assign LEDR[0] = finished;

    logic [7:0] sIn;
    logic [7:0] sOut;
    logic [7:0] sAddr;
    logic sWren;

    logic [7:0] aIn;
    logic [7:0] aAddr;
    logic aWren;

    logic [7:0] kOut;
    logic [4:0] kAddr;
    
    
    logic [2:0][7:0] switchKey;
    logic keySel;
    assign keySel = 1;
    assign switchKey = {14'b0, SW[9:0]};
    
    trap_edge reset_trapper(
        .clk(clk),
        .in(reset),
        .out(reset_sig)
    );


    arcfour RC(
        .clk(clk),
        .reset(reset_sig),
        .switch_key(switchKey),
        .start(start),
        .arcfour_finished(finished),
        .sIn(sIn),
        .sAddr(sAddr),
        .sWren(sWren),
        .sOut(sOut),
        .kAddr(kAddr),
        .kOut(kOut),
        .aAddr(aAddr),
        .aIn(aIn),
        .aWren(aWren),
        .key_select(keySel)
    );


    //TODO: integrate ramcore into arcfour module
    //read enable is by default high
    ramcore S (
        .address(sAddr),
        .clock(clk),
        .data(sIn),
        .wren(sWren),
        .q(sOut)
    );


    ramcore A(
        .address(aAddr),
        .clock(clk),
        .data(aIn),
        .wren(aWren)
    );


    romcore K(
        .address(kAddr),
        .clock(clk),
        .q(kOut)
    );

endmodule