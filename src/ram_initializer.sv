
module ram_initializer
    #(
        parameter RAM_WIDTH = 8
    )
    (
        input logic clk,
        input logic start,
        
        output logic write_enable,
        output logic [RAM_WIDTH - 1 : 0] ram_in,
        output logic [RAM_WIDTH - 1 : 0] address,

        output logic done
    );

    logic [RAM_WIDTH - 1 : 0] next_ram_in;
    logic [RAM_WIDTH - 1 : 0] next_address;

    logic enable;
    logic next_done;


    trap_edge trapper(
        .clk(clk),
        .reset(done),
        .async_sig(start),
        .trapped_edge(enable)
    );

    assign write_enable = enable;
    
    
    always_comb begin
        if(address < 255)begin
            next_done = 0;
            if(enable) begin
                next_address = address + 1;
                next_ram_in = ram_in + 1;
            end
            else begin
                next_address = 0;
                next_ram_in = 0;
            end
        end
        else begin //thinks its at 256
            if(enable) next_done = 1;
            else next_done = 0;
            next_address = 0;
            next_ram_in = 0;
        end
    end



    always_ff @(posedge clk) begin
        if(~enable) begin
            address <= 0;
            ram_in <= 0;
            done <= 0;
        end
        else begin
            address <= next_address;
            ram_in <= next_ram_in;
            done <= next_done;
        end
    end




endmodule