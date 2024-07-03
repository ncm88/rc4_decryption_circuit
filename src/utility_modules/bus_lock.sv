//Sets outbus to new inbus value every cycle that trigger is high
module bus_lock
    #(
        parameter BUS_WIDTH
    )
    (
        input logic clk, 
        input logic reset, 
        input logic trigger,
        input logic [BUS_WIDTH-1:0] inBus,
        output logic [BUS_WIDTH-1:0] outBus
    );

    logic[BUS_WIDTH-1:0] next_bus;
    assign next_bus = trigger? inBus : outBus;

    always_ff @(posedge clk) begin
        if(reset) outBus <= 0;
        else outBus <= next_bus;  
    end

endmodule