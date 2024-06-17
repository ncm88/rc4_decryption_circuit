module arcfour_tb();
    logic [7:0] ram_in;
    logic [7:0] ram_out;
    logic [7:0] address;
    logic write_enable;
    logic arcfour_finished;
    logic clk;
    logic [2:0] state;
    logic start;
    logic reset;
    logic [1:0] fTap;
    logic [23:0] key;
    assign key = {24'b0};
    assign ram_out = 0;

    logic[7:0]iTap;
    logic[7:0]jTap;
    logic[7:0]siTap;
    logic[7:0]sjTap;
    logic readTap, writeTap;
    logic fStartTap;

    arcfour RC(
        .clk(clk),
        .reset(reset),
        .key(key),
        .start_sig(start),
        .arcfour_finished(arcfour_finished),
        .ram_out(ram_out),
        .write_enable(write_enable),
        .ram_in(ram_in),
        .address(address),
        .state_tap(state),
        .fTap(fTap),
        .iTap(iTap),
        .jTap(jTap),
        .siTap(siTap),
        .sjTap(sjTap),
        .readTap(readTap),
        .writeTap(writeTap),
        .fStartTap(fStartTap)
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
        #3000
        start = 0;
        #60
        start = 1;
        #100
        start = 0;
        #12000
        start = 1;
        #5000
        start = 0;
    end


    initial begin
        #25000
        $finish;
    end




endmodule