

module decryptor_tb#(
    parameter RAM_WIDTH = 8,
    parameter RAM_LENGTH = 8,
    parameter MESSAGE_LENGTH = 32,
    parameter MESSAGE_LOG_LENGTH = 5
)();

    logic clk;
    logic start;
    logic reset;

    logic [RAM_WIDTH-1:0] sOut;
    logic [RAM_WIDTH-1:0] sIn;
    logic [RAM_LENGTH-1:0] sAddr;
    logic sWren;

    logic [RAM_WIDTH-1:0] aIn;
    logic [RAM_LENGTH-1:0] aAddr;
    logic aWren;

    logic [RAM_WIDTH-1:0] kOut;
    logic [MESSAGE_LOG_LENGTH-1:0] kAddr;


    logic [7:0] iTap;
    logic [7:0] jTap;
    logic [7:0] kTap;
    logic [7:0] stateTap;
    logic [7:0] siTap;
    logic [7:0] sjTap;


    decryptor DUT(
        .clk(clk),
        .start(start),
        .reset(reset),
        .sOut(sOut),
        .sIn(sIn),
        .sAddr(sAddr),
        .sWren(sWren),
        .aIn(aIn),
        .aAddr(aAddr),
        .aWren(aWren),
        .kOut(kOut),
        .kAddr(kAddr),
        .iTap(iTap),
        .jTap(jTap),
        .kTap(kTap),
        .siTap(siTap),
        .sjTap(sjTap),
        .stateTap(stateTap)
    );


    assign sOut = 8'b00011000;
    assign kOut = 8'b00000011;




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
    end


    initial begin
        #25000
        $finish;
    end




endmodule


/*
module virtualRAM
    (
        input logic clk,
        input logic wren,
        input logic[7:0] addr,
        input logic[7:0] in, 
        output logic[7:0] out
    );

    logic[255:0][7:0] mem;

    always_ff @(posedge clk) begin
        if(wren)mem[addr] <= in;
        else mem[addr] <= mem[addr];
        out <= mem[addr];
    end

endmodule



module virtualROM
    (
        input logic clk,
        input logic[7:0] addr, 
        output logic[7:0] out
    );

    logic[31:0][7:0] mem;

    initial begin
        integer i;
        for(i = 0; i < 32; i = i+1)begin
            mem[i] = i;
        end
    end

    always_ff @(posedge clk) begin
        out <= mem[addr];
    end

endmodule
*/