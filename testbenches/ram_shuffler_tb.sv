module ram_shuffler_tb();
    logic clk;
    logic reset;
    logic start;
    logic finished;
    logic [7 : 0] ram_out;
    logic [2:0][7:0] key;
    logic write_enable;
    logic [7 : 0] ram_in;
    logic [7 : 0] address;
    logic [7:0] iTap;
    logic [7:0] jTap;
    logic [4:0] stateTap;
    logic [7:0] siTap;
    logic [7:0] sjTap;
    logic readTap;
    logic writeTap;
    
    ram_shuffler #(.RAM_LENGTH(8'd8), .RAM_WIDTH(8'd8), .KEY_LENGTH(8'd3)) shuffler(
        .clk(clk),
        .reset(reset),
        .start(start),
        .finished(finished),
        .ram_out(ram_out),
        .key(key),
        .write_enable(write_enable),
        .ram_in(ram_in),
        .address(address),
        .iTap(iTap),
        .jTap(jTap),
        .stateTap(stateTap),
        .siTap(siTap),
        .sjTap(sjTap)
    );


    assign key = 1;
    assign ram_out = 8'b01000000;

    always begin
        #5;
        clk = ~clk;
    end


    initial begin
        reset = 0;
        clk = 0;
        start = 0;
        #60
        reset = 1;
        #30
        reset = 0;
        #150
        start = 1;
        #1700
        start = 0;
        #200
        start = 1;
        #500 
        start = 0;
        #270
        start = 1;
        #15000;
        start = 0;
        #100
        start = 1;
    end


    initial begin
        #25000
        $finish;
    end


endmodule