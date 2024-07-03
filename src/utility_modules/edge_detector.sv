module edge_detector       
    (
        input logic clk,
        input logic in,
        output logic out
    );

    logic last_in;
    logic next_out;

    always_comb begin
        if(in && ~last_in) next_out = 1;
        else next_out = 0;
    end

    always_ff @( posedge clk ) begin 
        out <= next_out;
        last_in <= in;
    end

endmodule
