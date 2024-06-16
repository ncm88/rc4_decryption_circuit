//This module controls multi-device acces to synchronous RAM resources

module ramcontroller
    #(
        parameter RAM_WIDTH = 8,
        parameter NUM_DEVICES = 2,
        parameter KEY_LENGTH = 3
    )
    (
        input logic clk,
        input logic reset,
        //////////////////////////////////////////Function select
        input logic [KEY_LENGTH-1:0][RAM_WIDTH-1:0] key,
        
        input logic [2:0] mode,
        input logic start,
        output logic finished,
        ////////////////////////////////////////RAM IO
        input logic [RAM_WIDTH - 1 : 0] ram_out,
        
        output logic write_enable,
        output logic [RAM_WIDTH - 1 : 0] ram_in,
        output logic [RAM_WIDTH - 1 : 0] address
    );

    logic [NUM_DEVICES - 1 : 0] start_bus;
    logic [NUM_DEVICES - 1 : 0] finished_bus;
    
    logic [NUM_DEVICES-1:0][RAM_WIDTH-1:0] ram_in_bus;
    logic [NUM_DEVICES-1:0][RAM_WIDTH-1:0] address_bus;
    logic [NUM_DEVICES - 1 : 0] write_enable_bus;


    ram_initializer intializer(
        .clk(clk),
        .reset(reset),
        .start(start_bus[0]),
        .finished(finished_bus[0]),
        .write_enable(write_enable_bus[0]),
        .ram_in(ram_in_bus[0]),
        .address(address_bus[0])
    );


    ram_shuffler shuffler(
        .clk(clk),
        .reset(reset),
        .start(start_bus[1]),
        .finished(finished_bus[1]),
        .ram_out(ram_out),
        .key(key),
        .write_enable(write_enable_bus[1]),
        .ram_in(ram_in_bus[1]),
        .address(address_bus[1])
    );



    always_comb begin
        case(mode)

            //Initialize RAM
            3'b001: begin   
                start_bus = {{(NUM_DEVICES - 1){1'b0}}, start};
                write_enable = write_enable_bus[0];
                ram_in = ram_in_bus[0];
                address = address_bus[0];
                finished = finished_bus[0];
            end

            3'b010: begin
                start_bus = {{(NUM_DEVICES - 2){1'b0}}, start, 1'b0};
                write_enable = write_enable_bus[1];
                ram_in = ram_in_bus[1];
                address = address_bus[1];
                finished = finished_bus[1];
            end


            default: begin
                start_bus = 0;
                ram_in = 0;
                address = 0;
                write_enable = 0;
                finished = 0;
            end

        endcase
    end


endmodule
