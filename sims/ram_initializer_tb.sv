module ram_initializer_tb();

    logic clk, start, write_enable, done, state_tap, clktap;
    logic [7:0] ram_in;
    logic [7:0] address;

    ram_initializer DUT(
        .clk(clk),
        .start(start),
        .write_enable(write_enable),
        .ram_in(ram_in),
        .address(address),
        .done(done),
        .state_tap(state_tap),
        .clktap(clktap)
    );


    always begin
        #5;
        clk = ~clk;
    end


    initial begin
        clk = 0;
        start = 0;
        #15
        start = 1;
        #1700
        start = 0;
        #200
        start = 1;
    end



    initial begin
        #4000
        $finish;
    end

endmodule