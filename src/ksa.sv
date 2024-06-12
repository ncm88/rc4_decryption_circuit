module ksa
    (
        input CLOCK_50,
        input [3:0] KEY,
        input [9:0] SW,
        input [9:0] LEDR,
        input [6:0] HEX0,
        input [6:0] HEX1,
        input [6:0] HEX2,
        input [6:0] HEX3,
        input [6:0] HEX4,
        input [6:0] HEX5
    );

    logic clk, rst, write_enable;
    
    assign clk = CLOCK_50;
    assign rst = SW[0];

    logic [7:0] address;
    logic [7:0] ram_in;
    logic [7:0] ram_out;

    //read enable is by default high
    ramcore S (
        .address(address),
        .clock(clk),
        .data(ram_in),
        .wren(write_enable),
        .q(ram_out)
    );


    always @(posedge clk) begin
        if(rst) begin
            address <= 0;
            ram_in <= 0;
            write_enable <= 0;
        end

        else if(address < 255) begin
            address <= address + 1;
            ram_in <= ram_in + 1;
            write_enable <= 1;
        end

        else begin
            address <= address;
            ram_in <= ram_in;
            write_enable <= 0;
        end
    end



                                      

endmodule