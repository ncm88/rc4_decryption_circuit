//TODO: multicore and lint
//TODO: fix hardcoded max key size of 24 bits


`default_nettype none
module ksa
    #(
        parameter NUM_CORES = 1,
        parameter MESSAGE_LENGTH = 32,
        parameter MESSAGE_LOG_LENGTH = 5,
        parameter KEY_LENGTH = 3    //Three byte key assumed by default
    )
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

    logic clk, start, reset;
    logic reset_sig;
    assign clk = CLOCK_50;
    assign reset = KEY[0]; //keys are active low
    assign start = KEY[1];


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
    
    key_toggle toggler(
        .in(KEY[2]),
        .clk(clk),
        .reset(reset_sig),
        .out(keySel)
    );

    //TODO: figure out arcfour start/reset signal characteristics
    assign switchKey = {14'b0, SW[9:0]};
    
    edge_detector reset_detector(
        .clk(clk),
        .in(reset),
        .out(reset_sig)
    );

    logic clear_start;
    edge_detector start_detector(
        .clk(clk),
        .in(start),
        .out(clear_start)
    );

    logic success, successOut;
    logic finished;

    trap_edge trapper(
        .in(success),
        .clk(clk),
        .reset(clear_start), 
        .out(successOut)
    );

    assign LEDR[0] = finished;
    assign LEDR[1] = successOut;
    assign LEDR[2] = keySel;


    arcfour #(
        .KEY_LENGTH(KEY_LENGTH),
        .KEY_UPPER(24'hffffff),
        .KEY_LOWER(0),
        .MESSAGE_LENGTH(MESSAGE_LENGTH),
        .MESSAGE_LOG_LENGTH(MESSAGE_LOG_LENGTH)
    ) RC
    (
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
        .key_select(keySel),
        .success(success)
    );


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