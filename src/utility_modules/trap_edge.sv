module trap_edge
    (
        input logic clk,
        input logic in,
        input logic reset,
        output logic out
    );

    logic last_in;
    logic next_out;

    always_comb begin
        if(in && ~last_in) next_out = 1;
        else next_out = out;
    end

    always_ff @( posedge clk ) begin 
        if(reset)begin
            out <= 0;
            last_in <= 0;
        end else begin
            out <= next_out;
            last_in <= in;
        end
    end

endmodule