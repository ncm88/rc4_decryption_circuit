//Sets outbus to new inbus value every cycle that trigger is high
module bus_lock
    #(
        parameter BUS_WIDTH
    )
    (
        input logic clk, 
        input logic reset, 
        input logic enable,
        input logic [BUS_WIDTH-1:0] inBus,
        output logic [BUS_WIDTH-1:0] outBus
    );

    always_ff @(posedge clk) begin
        if(reset) outBus <= 0;
        else if(enable) outBus <= inBus;
        else outBus <= outBus;  
    end

endmodule