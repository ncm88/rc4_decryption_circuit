module key_generator_tb();

    logic clk;
    logic reset;
    logic start;
    logic finished;
    logic terminated;
    logic [23:0] key;


    key_generator #(.KEY_UPPER(24'h000002), .KEY_LOWER(24'h000000)) DUT(
        .clk(clk),
        .reset(reset),
        .start(start),
        .finished(finished),
        .terminated(terminated),
        .key(key)
    );

    initial begin           //Full disclosure I know this testbench is braindead
        clk = 0;
        start = 0;
        reset = 1;
        #100
        reset = 0;
    end

    always begin
        #150
        start = ~start;
    end


    always begin
        #5
        clk = ~clk;
    end







endmodule