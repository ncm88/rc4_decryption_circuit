module core_pull
    #(
        parameter RAM_WIDTH,
        parameter KEY_LENGTH,
        parameter NUM_CORES,
        parameter LOG_NUM_CORES
    )
    (
        input logic clk,
        input logic reset,
        input logic enable,
        input logic [LOG_NUM_CORES-1:0] addr,
        input logic [LOG_NUM_CORES-1:0][RAM_WIDTH*KEY_LENGTH-1:0] keys,
        output logic [RAM_WIDTH*KEY_LENGTH-1:0] out_key,
        output logic [LOG_NUM_CORES-1:0] out_addr
    );
    
    logic [RAM_WIDTH*KEY_LENGTH-1:0] next_key;
    assign next_key = keys[addr];

    always_ff @(posedge clk) begin
        if(reset) begin
            out_addr <= 0;
            out_key <= 0;
        end
        
        else if(enable) begin
            out_addr <= addr;
            out_key <= next_key;
        end
        
        else begin
            out_addr <= out_addr;
            out_key <= out_key;
        end
    end    

endmodule