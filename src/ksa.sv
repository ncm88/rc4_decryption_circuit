module ksa
    (
        input CLOCK_50,
        input [3:0] KEY,
        input [9:0] SW,
        output [9:0] LEDR,
        input [6:0] HEX0,
        input [6:0] HEX1,
        input [6:0] HEX2,
        input [6:0] HEX3,
        input [6:0] HEX4,
        input [6:0] HEX5
    );


    typedef enum logic [2:0] {
        IDLE = 3'b000,
        INIT_RAM = 3'b001,
        SHUFFLE_RAM = 3'b010
    } state_t;

    typedef enum logic [2:0] {
        IDLE_MODE = 3'b000,
        INIT_MODE = 3'b001,
        SHUFFLE_MODE = 3'b010
    } mode_t;


    state_t state, next_state;
    mode_t mode, next_mode;
    logic [1:0] state_indicator, fail_indicator;
    
    assign LEDR[1:0] = state_indicator;
    assign LEDR[2] = fail_indicator;

    logic clk, reset; 
    logic start_sig;                //TODO: make finish signal last until cleared; NOTE: keys are active low


    assign clk = CLOCK_50;
    logic start, next_start;
    logic finished, next_finished;

    logic [23:0] switch_key;
    assign switch_key = {14'b0,SW[9:1], 1'b0};


    logic [7:0] address;
    logic [7:0] ram_in;
    logic [7:0] ram_out;
    logic write_enable;

    assign reset = SW[0];
    
    /*
    trap_edge reset_trapper(
        .clk(clk),
        .in(KEY[0]),
        .out(reset)
    );
*/
    trap_edge start_trapper(
        .clk(clk),
        .in(KEY[0]),
        .out(start_sig)
    );



    ramcontroller controller(
        .clk(clk),
        .reset(reset),
        .start(start),
        .finished(next_finished),
        .mode(mode),
        .ram_out(ram_out),
        .address(address),
        .ram_in(ram_in),
        .write_enable(write_enable)
    );


    //read enable is by default high
    ramcore S (
        .address(address),
        .clock(clk),
        .data(ram_in),
        .wren(write_enable),
        .q(ram_out)
    );



    //State transition logic
    always_comb begin
        next_start = ~start;
        case(state)
            IDLE: begin
                if(start_sig) next_state = INIT_RAM;
                else next_state = IDLE;
            end

            INIT_RAM: begin
                if(finished) next_state = SHUFFLE_RAM;
                else next_state = INIT_RAM;
            end

            SHUFFLE_RAM: begin
                if(finished) next_state = IDLE;
                else next_state = SHUFFLE_RAM;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end



    always_ff begin
        if(reset)begin
            state <= IDLE;
            mode <= IDLE_MODE;
            start <= 0;
            finished <= 0;
        end else begin
            state <= next_state;
            mode <= next_mode;
            start <= next_start;
            finished <= next_finished;
        end
    end


    always_comb begin
        case(next_state)
            IDLE: next_mode = IDLE_MODE;
            INIT_RAM: next_mode = INIT_MODE;
            SHUFFLE_RAM: next_mode = SHUFFLE_MODE;
            default: next_mode = IDLE_MODE;
        endcase
    end









    always_comb begin
        case(state)
            IDLE: begin
                state_indicator = 2'b01;
                fail_indicator = 0;
            end

            INIT_RAM: begin
                state_indicator = 2'b10;
                fail_indicator = 0;
            end

            SHUFFLE_RAM: begin
                state_indicator = 2'b11;
                fail_indicator = 0;
            end

            default: begin
                state_indicator = 2'b00;
                fail_indicator = 1;
            end
        endcase
    end



endmodule