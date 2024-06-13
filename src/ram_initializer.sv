
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

        output logic done,
        
        output logic state_tap,
        output logic clktap
    );

    localparam IDLE = 1'b0;
    localparam SEED_SEQUENCE = 1'b1;

    logic state;
    logic next_state;
    logic next_write_enable, next_done;
    logic [RAM_WIDTH - 1 : 0] next_ram_in;
    logic [RAM_WIDTH - 1 : 0] next_address;


    logic start_ack;
    logic clear, next_clear;

/*
    //I love FPGAS
    initial begin
        state = IDLE;
        clear = 0;
        done = 0;
        write_enable = 0;
        ram_in = 0;
        address = 0;
        start_ack = 0;
    end
*/

    assign clktap = clk;

    trap_edge trapper(
        .clk(clk),
        .reset(clear),
        .async_sig(start),
        .trapped_edge(start_ack)
    );



    //state change and clear logic
    always_comb begin
        case(state)
            IDLE: begin
                if(start_ack)begin
                    next_state = SEED_SEQUENCE;
                    next_clear = 1;
                end
            
                else begin
                    next_state = IDLE;
                    next_clear = 0;
                end
            end

            SEED_SEQUENCE: begin
                if(address < 255) begin
                    next_state = SEED_SEQUENCE;
                    next_clear = 0;
                end
                else begin
                    next_state = IDLE;
                    next_clear = 1;
                end
            end
        endcase
    end



    always_ff @(posedge clk) begin
        clear <= next_clear;
        state <= next_state;
        address <= next_address;
        ram_in <= next_ram_in;
        write_enable <= next_write_enable;
        done <= next_done;
        state_tap <= state;
    end


    //output logic
    always_comb begin 
        case(state)
            IDLE: begin
                next_address = 0;
                next_ram_in = 0;
                if(start_ack) begin
                    next_done = 0;
                    next_write_enable = 1;
                end
                
                else begin
                    next_done = done;
                    next_write_enable = 0;
                end
            end

            SEED_SEQUENCE: begin
                if(address < 255) begin
                    next_address = address + 1;
                    next_ram_in = ram_in + 1;
                    next_write_enable = 1;
                    next_done = 0;          //"Job's not finished" -Kobe
                end
                else begin
                    next_address = 0;
                    next_ram_in = 0;
                    next_write_enable = 0;
                    next_done = 1;
                end
            end
        endcase
    end



endmodule