//This module controls multi-device acces to synchronous RAM resources

module ramcontroller
    #(
        parameter RAM_WIDTH,
        parameter RAM_LENGTH,
        parameter NUM_DEVICES = 3,
        parameter KEY_LENGTH,
        parameter MESSAGE_LENGTH,
        parameter MESSAGE_LOG_LENGTH
    )
    (
        input logic clk,
        input logic reset,

        //////////////////////////////////////////Function select
        input logic [KEY_LENGTH-1:0][RAM_WIDTH-1:0] key,
        input logic[5:0] mode,
        output logic [NUM_DEVICES-1:0] finish_bus,

        ////////////////////////////////////////RAM IO
        output logic sWren,
        input logic [RAM_WIDTH - 1 : 0] sOut,
        output logic [RAM_WIDTH - 1 : 0] sIn,
        output logic [RAM_WIDTH - 1 : 0] sAddr,

        input logic [RAM_WIDTH-1:0] kOut,
        output logic [MESSAGE_LOG_LENGTH-1:0] kAddr,

        output logic [RAM_WIDTH-1:0] aIn,
        output logic [RAM_LENGTH-1:0] aAddr,
        output logic aWren,
        output logic success,

        output logic[7:0]iTap,          //TEST
        output logic[7:0]jTap,
        output logic[7:0]siTap,
        output logic[7:0]sjTap,
        output logic[7:0]kTap,
        output logic [7:0] stateTap,
        output logic wrenTap
    );


    logic [NUM_DEVICES - 1 : 0] start_bus;
    logic [NUM_DEVICES-1:0][RAM_WIDTH-1:0] sInBus;
    logic [NUM_DEVICES-1:0][RAM_WIDTH-1:0] sAddrBus;
    logic [NUM_DEVICES - 1 : 0] sWrenBus;


    ram_initializer #(
        .RAM_WIDTH(RAM_WIDTH),
        .RAM_LENGTH(RAM_LENGTH)
    ) initializer(
        .clk(clk),
        .reset(reset),
        .start(start_bus[0]),
        .finished(finish_bus[0]),
        .write_enable(sWrenBus[0]),
        .ram_in(sInBus[0]),
        .address(sAddrBus[0])
    );


    ram_shuffler #(
        .RAM_WIDTH(RAM_WIDTH),
        .RAM_LENGTH(RAM_LENGTH),
        .KEY_LENGTH(KEY_LENGTH)
    ) shuffler(
        .clk(clk),
        .reset(reset),
        .start(start_bus[1]),
        .finished(finish_bus[1]),
        .ram_out(sOut),
        .key(key),
        .write_enable(sWrenBus[1]),
        .ram_in(sInBus[1]),
        .address(sAddrBus[1])
    );


    decryptor #(
        .RAM_WIDTH(RAM_WIDTH),
        .RAM_LENGTH(RAM_LENGTH),
        .MESSAGE_LENGTH(MESSAGE_LENGTH),
        .MESSAGE_LOG_LENGTH(MESSAGE_LOG_LENGTH)
    ) decryptor
    (
        .clk(clk),
        .reset(reset),
        .start(start_bus[2]),
        .sOut(sOut),
        .sAddr(sAddrBus[2]),
        .sWren(sWrenBus[2]),
        .sIn(sInBus[2]),
        .aIn(aIn),
        .aAddr(aAddr),
        .aWren(aWren),
        .kOut(kOut),
        .kAddr(kAddr),
        .finished(finish_bus[2]),
        .iTap(iTap),
        .jTap(jTap),
        .kTap(kTap),
        .siTap(siTap),
        .sjTap(sjTap),
        .stateTap(stateTap),
        .wrenTap(wrenTap),
        .success(success)
    );
    

    always_comb begin
        case(mode)

            6'b001_000: begin   
                start_bus = {{(NUM_DEVICES - 1){1'b0}}, 1'b1};
                sWren = sWrenBus[0];
                sIn = sInBus[0];
                sAddr = sAddrBus[0];
            end

            6'b010_000: begin
                start_bus = {{(NUM_DEVICES - 2){1'b0}}, 1'b1, 1'b0};
                sWren = sWrenBus[1];
                sIn = sInBus[1];
                sAddr = sAddrBus[1];
            end

            
            6'b011_000: begin
                start_bus = {{(NUM_DEVICES - 3){1'b0}}, 1'b1, 2'b0};
                sWren = sWrenBus[2];
                sIn = sInBus[2];
                sAddr = sAddrBus[2];
            end
            
            default: begin      //For IDLE/Key acquisition states
                start_bus = 0;
                sWren = 0;
                sAddr = 0;
                sIn = 0;
            end

        endcase
    end
endmodule
