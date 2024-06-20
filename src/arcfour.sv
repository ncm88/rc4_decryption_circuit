module arcfour
    #(
        parameter RAM_WIDTH = 8,
        parameter RAM_LENGTH = 8,
        parameter NUM_DEVICES = 3,
        parameter KEY_LENGTH = 3,
        parameter MESSAGE_LOG_LENGTH = 5
    )
    (
        input logic clk,
        input logic reset,
        input logic start_sig,

        input logic [KEY_LENGTH-1:0][RAM_WIDTH-1:0] key,
        output logic arcfour_finished,

        /////////////////////////////RAM-S
        output logic sWren,
        input logic [RAM_WIDTH - 1 : 0] sOut,
        output logic [RAM_WIDTH - 1 : 0] sIn,
        output logic [RAM_WIDTH - 1 : 0] sAddr,

        ////////////////////////////ROM-K
        input logic [RAM_WIDTH-1:0] kOut,
        output logic [MESSAGE_LOG_LENGTH-1:0] kAddr,

        //////////////////////////////RAM-A
        output logic [RAM_WIDTH-1:0] aIn,
        output logic [RAM_LENGTH-1:0] aAddr,
        output logic aWren,

        /////////////////////////////////TEST
        output logic[7:0]iTap,
        output logic[7:0]jTap,
        output logic[7:0]siTap,
        output logic[7:0]sjTap,
        output logic [7:0] stateTap,
        output logic [7:0] kTap,
        output logic [2:0] fTap,
        output logic [2:0] modeTap,
        output logic wrenTap
    );

    logic next_arcfour_finished;

    typedef enum logic [2:0] {
        IDLE = 3'b000,
        INIT_RAM = 3'b001,
        SHUFFLE_RAM = 3'b010,
        DECRYPT_RAM = 3'b100
    } state_t;

    state_t state, next_state;
    assign modeTap = state;

    logic [NUM_DEVICES-1:0] finished;
    logic [NUM_DEVICES-1:0] next_finished;
    assign fTap = finished;

    ramcontroller controller(
        .clk(clk),
        .reset(reset),
        .finish_bus(next_finished),
        .mode(state),
        .sIn(sIn),
        .sAddr(sAddr),
        .sWren(sWren),
        .sOut(sOut),
        .kAddr(kAddr),
        .kOut(kOut),
        .aAddr(aAddr),
        .aIn(aIn),
        .aWren(aWren),
        .key(key),
        .iTap(iTap),
        .jTap(jTap),
        .siTap(siTap),
        .sjTap(sjTap),
        .stateTap(stateTap),
        .kTap(kTap),
        .wrenTap(wrenTap)
    );



    //State transition logic
    always_comb begin
        case(state)
            IDLE: begin
                if(start_sig) begin
                    next_state = INIT_RAM;
                    next_arcfour_finished = 0;
                end
                else begin
                    next_state = IDLE;
                    next_arcfour_finished = arcfour_finished;
                end
            end

            INIT_RAM: begin
                if(finished[0]) next_state = SHUFFLE_RAM;
                else next_state = INIT_RAM;
                next_arcfour_finished = 0;
            end

            SHUFFLE_RAM: begin
                if(finished[1])begin
                    next_state = DECRYPT_RAM;
                    next_arcfour_finished = 0;
                end
                else begin 
                    next_state = SHUFFLE_RAM;
                    next_arcfour_finished = 0;
                end
            end

            DECRYPT_RAM: begin
                if(finished[2])begin
                    next_state = IDLE;
                    next_arcfour_finished = 1;
                end
                else begin 
                    next_state = DECRYPT_RAM;
                    next_arcfour_finished = 0;
                end
            end

            default: begin
                next_state = IDLE;
                next_arcfour_finished = 0;
            end
        endcase
    end


    always_ff @( posedge clk ) begin
        if(reset)begin
            state <= IDLE;
            finished <= 0;
            arcfour_finished <= 0;
        end else begin
            state <= next_state;
            finished <= next_finished;
            arcfour_finished <= next_arcfour_finished;
        end
    end


endmodule