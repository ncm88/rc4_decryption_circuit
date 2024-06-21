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
    logic start_sig;
    assign clk = CLOCK_50;
    assign reset = SW[0]; //keys are active low
    assign start = SW[1];
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
    
    
    //TODO: get rid of explicit key stuff
    logic [2:0][7:0] key;
    //assign key = 24'b01001001_00000010_00000000;

    assign key[0] = 8'b0;
    assign key[1] = 8'b00000010;
    assign key[2] = 8'b01001001;

    trap_edge start_trapper(
        .clk(clk),
        .in(start),
        .out(start_sig)
    );
    

    arcfour RC(
        .clk(clk),
        .reset(reset),
        .key(key),
        .start_sig(start_sig),
        .arcfour_finished(finished),
        .sIn(sIn),
        .sAddr(sAddr),
        .sWren(sWren),
        .sOut(sOut),
        .kAddr(kAddr),
        .kOut(kOut),
        .aAddr(aAddr),
        .aIn(aIn),
        .aWren(aWren)
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