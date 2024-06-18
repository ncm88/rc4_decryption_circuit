module rom_loader_tb#(
        parameter KEY_LENGTH = 32,
        parameter ROM_LENGTH = 5,
        parameter ROM_WIDTH = 8
    )();

    logic clk;
    logic reset;
    logic start;

    logic [KEY_LENGTH-1:0][ROM_WIDTH-1:0] key_arr;
    logic finished;

    logic [2:0] state_tap;
    logic [ROM_LENGTH-1:0] address;
    logic [7:0] out_tap;

    logic[ROM_WIDTH-1:0] rom_out;
    assign rom_out = 8'b00000001;

    rom_loader loader(
        .clk(clk),
        .reset(reset),
        .start(start),
        .rom_out(rom_out),
        .address(address),
        .key_arr(key_arr),
        .finished(finished),
        .state_tap(state_tap),
        .out_tap(out_tap)
    );


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
        #2000
        reset = 1;
        #100;
        reset = 0;
        start = 0;
        #20;
        start = 1;
    end



    initial begin
        #15000
        $finish;
    end




endmodule