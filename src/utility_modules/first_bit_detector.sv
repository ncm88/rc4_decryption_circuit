module first_bit_detector ///Gets index of least significant high bit
    #(
        parameter BUS_WIDTH,
        parameter LOG_BUS_WIDTH
    )
    (
        input logic[BUS_WIDTH-1:0] bus,
        output logic [LOG_BUS_WIDTH-1:0] addr
    );

    always_comb begin
        if(bus == 0) addr = 0;
        else begin
            addr = 0; 
            for (int i = 0; i < BUS_WIDTH; i++) begin
                if (bus[i]) begin
                    addr = i; 
                    break; 
                end
            end
        end
    end
endmodule