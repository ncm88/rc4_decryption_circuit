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

    logic succeeded;
    logic terminated;

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


    arcfour #(
        .RAM_WIDTH(8),
        .RAM_LENGTH(8),
        .KEY_LENGTH(3),
        .MESSAGE_LENGTH(32),
        .MESSAGE_LOG_LENGTH(5),
        .KEY_UPPER(24'hffffff),
        .KEY_LOWER(0)
    ) RC
    (
        .clk(clk),
        .reset(reset),
        .switch_key(key),
        .start(start),

        .succeeded(succeeded),
        .terminated(terminated),

        .key_select(key_select),

        .sOut(sOut),
        .sWren(sWren),
        .sIn(sIn),
        .sAddr(sAddr),
        
        .kOut(kOut),
        .kAddr(kAddr),
        .outKey(keyTap),
        .aWren(aWren),
        .aIn(aIn),
        
        /*
        .stateTap(state),
        .kTap(kTap),
        .iTap(iTap),
        .jTap(jTap),
        .siTap(siTap),
        .sjTap(sjTap),
        .fTap(fTap),
        .modeTap(modeTap),
        .wrenTap(wrenTap)
        */

        .aAddr(aAddr)

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