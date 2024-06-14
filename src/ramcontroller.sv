//This module controls multi-device acces to synchronous RAM resources

module ramcontroller
    #(
        parameter RAM_WIDTH = 8,
        parameter NUM_DEVICES = 1,
        parameter RAM_SIZE = 256
    )
    (
        input logic clk,
        input logic reset,
        //////////////////////////////////////////Function select
        input logic [2:0] mode,
        input logic start,
        output logic [NUM_DEVICES - 1:0] finished_bus,
        ////////////////////////////////////////RAM IO
        output logic [NUM_DEVICES - 1: 0 ] wrenbus,
        output logic [NUM_DEVICES*RAM_WIDTH - 1 : 0] ram_in,
        output logic [NUM_DEVICES*RAM_WIDTH - 1 : 0] address
    );

    logic [NUM_DEVICES - 1:0] start_bus;

    logic initializer_write_enable;
    logic [RAM_WIDTH-1 : 0] initializer_ram_in;
    logic [RAM_WIDTH-1 : 0] initializer_address;
    logic [1:0] state;

    logic [RAM_SIZE - 1 : RAM_WIDTH - 1] working_mem;

    ram_initializer intializer(
        .clk(clk),
        .start(start_bus[0]),
        .finished(finished_bus[0]),
        .write_enable(initializer_write_enable),
        .ram_in(initializer_ram_in),
        .address(initializer_address),
        .state(state),
        .reset(reset)
    );

    always_comb begin
        case(mode)
            
            //Initialize RAM
            3'b001: begin   
                start_bus = {{(NUM_DEVICES - 1){1'b0}}, start};
                wrenbus = { {(NUM_DEVICES - 1){1'b0}}, initializer_write_enable };
                ram_in = { {(RAM_WIDTH * (NUM_DEVICES - 1)){1'b0}}, initializer_ram_in };
                address = { {(RAM_WIDTH * (NUM_DEVICES - 1)){1'b0}}, initializer_address };
            end

            default: begin
                start_bus = 0;
                wrenbus = 0;
                ram_in = 0;
                address = 0;
            end

        endcase
    end


endmodule
