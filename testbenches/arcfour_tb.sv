module arcfour_tb();
    logic [7:0] sIn;
    logic [7:0] sOut;
    logic [7:0] sAddr;
    logic sWren;

    logic [7:0] kOut;
    logic [4:0] kAddr;

    logic [7:0] aIn;
    logic [7:0] aAddr;
    logic aWren;

    logic arcfour_finished;
    logic arcfour_terminated;

    logic clk;
    logic [7:0] state;
    logic start;
    logic reset;
    logic [23:0] key;
    assign key = 24'b01001001_00000010_00000000;

    assign sOut = 8'b00011000;
    assign kOut = 8'b00000011;


    logic[7:0]iTap;
    logic[7:0]jTap;
    logic[7:0]siTap;
    logic[7:0]sjTap;
    logic[7:0]kTap;
    logic [2:0] fTap;
    logic [5:0] modeTap;
    logic wrenTap;
    logic [2:0][7:0] keyTap;


    logic key_select;
    assign key_select = 1'b0;


    arcfour RC(
        .clk(clk),
        .reset(reset),
        .switch_key(key),
        .start(start),
        .arcfour_finished(arcfour_finished),
        .arcfour_terminated(arcfour_terminated),
        .key_select(key_select),
        .keyTap(keyTap),

        .sOut(sOut),
        .sWren(sWren),
        .sIn(sIn),
        .sAddr(sAddr),
        
        .kOut(kOut),
        .kAddr(kAddr),

        .aWren(aWren),
        .aIn(aIn),
        .aAddr(aAddr),
        
        .stateTap(state),
        .kTap(kTap),
        .iTap(iTap),
        .jTap(jTap),
        .siTap(siTap),
        .sjTap(sjTap),
        .fTap(fTap),
        .modeTap(modeTap),
        .wrenTap(wrenTap)
    );


    always begin
        #5;
        clk = ~clk;
    end


    initial begin
        clk = 0;
        start = 0;
        reset = 1;
        #150
        reset = 0;
        #7
        start = 1;

    end


    initial begin
        #55000
        $finish;
    end




endmodule