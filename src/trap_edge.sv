module trap_edge
    (
        input logic clk,
        input logic reset,
        input logic async_sig,
        output logic trapped_edge
    );

    logic last_async;

    always_ff @( posedge clk or posedge reset ) begin 
        if(reset) begin
            trapped_edge <= 0;
            last_async <= 0;
        end
        else if(async_sig && ~last_async) trapped_edge <= 1;

        else trapped_edge <= trapped_edge;
        last_async <= async_sig;
    end

endmodule