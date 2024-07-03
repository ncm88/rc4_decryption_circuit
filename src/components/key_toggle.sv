module key_toggle
    (
        input logic clk,
        input logic reset,
        input logic in,
        output logic out
    );

    logic last_in, next_out;

    always_comb begin
        if(in && ~last_in) next_out = ~out;
        else next_out = out;
    end

    always_ff @(posedge clk) begin
        if(reset) begin
            out <= 0;
            last_in <= 0;
        end else begin
            out <= next_out;
            last_in <= in;
        end
    end

endmodule