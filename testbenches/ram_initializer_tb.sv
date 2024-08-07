module ram_initializer_tb();

    logic clk, start, write_enable, finished, state, reset;
    logic [7:0] ram_in;
    logic [7:0] address;


    ram_initializer DUT(
        .clk(clk),
        .start(start),
        .write_enable(write_enable),
        .ram_in(ram_in),
        .address(address),
        .finished(finished),
        .reset(reset)
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
    end



    initial begin
        #8000
        $finish;
    end

endmodule