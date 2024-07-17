# Multi-Core RC4 Hardware Decryption Engine


## Brief
[RC4](https://people.computing.clemson.edu/~jmarty/courses/commonCourseContent/AdvancedModule-SecurityConceptsAndApplicationToLinux/RC4ALGORITHM-Stallings.pdf) is a stream cipher designed by Ron Rivest in 1987. It was widely used in various protocols such as SSL/TLS and WEP/WPA for its simplicity and speed in software. RC4 generates a pseudorandom stream of bits (a keystream) which is XORed with the plaintext to produce the ciphertext. However there is one key weakness to RC4 and it is the reason why it is no longer used for sensitive data: the decryption process is identical to encryption. In other words, the ciphertext XORed with the same keystream it was encrypted with can be used to retrieve the plaintext.

The decryption engine is designed to exploit this property by repeatedly generating keystreams and testing decrypted outputs until a valid output is detected, at which point all cores cease operation and the key used to break encryption is returned to the user as well as the number of the core which obtained it. This information can then be used to view the decrypted message directly (via in-system memory content editor lookup at core address) or indirectly (returning key to a generic processor for application of the same decryption algorithm by said processor). Of course, the memory address of the newly decrypted message could also be passed to the HPS for direct lookup but I suspect that this would require a bit more work to implement and the additional overhead by running the decryption algorithm just one extra time on the HPS is quite trivial in comparision to the average message brute force decryption time.

For anyone looking to do something similar in the future, a list of [nontrivial issues](#nontrivialities) I encountered during development is attached at the bottom of this document.

## System Overview
The device can be expressed in terms of six individual FSM's. The first FSM is the top level module and dictates the input/output behaviour of the system. The other five compose the decryption core. All FSM's operate using a simple start-finish protocol and are completely memoryless in the sense that each cycle of operation has no reliance on the previous.

### 1. Top-Level FSM (ksa.sv)
Consists of four states: `RUNNING`, `IDLE_OR_FAIL`, `SUCCESS`, and `RESET`. The system is initialized in the `IDLE_OR_FAIL` state. When the rising edge of a dedicated reset signal is registered, the system transfers to the `RESET` state where all outputs and registered values are cleared and the state is thereafter returned to `FAIL_OR_IDLE`, this approach was employed in order to have more customization over system reset characteristics in the future. 

The system is started by the rising edge of a dedicated `start` signal. If the system is in states `IDLE_OR_FAIL` or `SUCCESS` when this edge is detected the state is moved to `RUNNING` thereafter where the core driver bit `start_bit` is raised, initializing the decryption sequence for all present cores within the bounds of their respective keyspaces.

Each decryption core has a termination signal which is raised when either a valid key is found (success) or all keys in the keyspace have been searched (fail), each core also has a dedicated success sig which is only raised when and if a valid key is found. These success and termination signals are then bussed together to compose `success_bus` and `termination_bus`. From these busses the global success and termination flags `success_sig` and `term_sig` are composed by OR-in `success_bus` and AND-ing `termination_bus`, the OR-ed output of `success_bus` with `term_bus` is used to drive a kill signal which transfers the system state from `RUNNING` to either `SUCCESS` or `FAIL` depending on if `success_bus` is high or not (i.e. if one core succeeds or all cores fail).

The states `SUCCESS` and `FAIL_OR_IDLE` are identical, save for `success_bit` being high on the former and low on the latter. In these states, the last present `core_ptr` and `curr_key`values are locked, these values are valid in the `SUCCESS` state and indicate the core that found the valid key (useful for memory lookup) and the valid key itself. When the system is in one of these states, it will remain in them until `start_sig` is registered upon which it will transition into the `RUNNING` and begin decrypting. As all sub-FSM's are memoryless, no additional reset logic is needed to facilitate this during repeated decryption cycle calls via `start_bit`.

Below is the state transistion logic:

``` plaintext
    FAIL_OR_IDLE: next_state = start_sig? RUNNING : FAIL_OR_IDLE;
    
    RUNNING: next_state = kill_sig? (success_sig? SUCCESS : FAIL_OR_IDLE) : RUNNING;
    
    SUCCESS: next_state = start_sig? RUNNING : SUCCESS;
    
    RESET: next_state = FAIL_OR_IDLE;
    
    default: next_state = FAIL_OR_IDLE;
```

__TLDR: Idles until start button is pressed, decrypts message when start button is pressed, idles again when either key is found or entire keyspace is searched giving successful core address and key value (if relevant), also indicates decryption success or failure at this time.__


### 2. Decryption Core Top-Level FSM (arcfour.sv)

Consists of four states: `IDLE`, `GET_KEY`, `INIT_RAM`, `SHUFFLE_RAM`, `DECRYPT_RAM`, `ARCFOUR_SUCCESS` and `ARCFOUR_FAIL`. States `GET_KEY` through `DECRYPT_RAM` call their appropriate FSM's while states `ARCFOUR_FAIL` and `ARCFOUR_SUCCESS` yield a termination flag (fail) and a termination and success flag (success) for their cycles respectively.

Below is the state transition logic:

```
    IDLE: next_state = start_sig? GET_KEY : IDLE;

    GET_KEY: begin
            if(key_sel) next_state = INIT_RAM;
            else next_state = key_finish? INIT_RAM : GET_KEY;
    end

    INIT_RAM: next_state = finished[0]? SHUFFLE_RAM : INIT_RAM;

    SHUFFLE_RAM: next_state = finished[1]? DECRYPT_RAM : SHUFFLE_RAM;

    DECRYPT_RAM: next_state = finished[2]? ((termination_flag || success)? (success? ARCFOUR_SUCCESS : ARCFOUR_FAIL) : GET_KEY) : DECRYPT_RAM;

    ARCFOUR_FAIL: next_state = IDLE;

    ARCFOUR_SUCCESS: next_state = IDLE;

    default: next_state = IDLE;

```

Note that in this case `start_sig` is produced by detection the risting edge of the `start_bit` signal fed into the `arcfour` module and `key_sel` is a logic value that dictates whether or not the device should generate through the keyspace or use the key provided by the DE-1 SoC's switches. If high, the switchkey input is used as the key and the core terminates after one cycle, otherwise it continues to execute `GET_KEY` through `DECRYPT_RAM` until either the entire provided keyspace is exhausted or a valid key is found.

__TLDR: If `key_sel` set uses switch key once and terminates otherwise generates a key and applies RC4 algorithm repeatedly until all keys in provided keyspace are exhausted.__


### 3. Key Generation FSM (key_generator.sv)

I know I said all FSM's here have have no state retention between invocations but this one is the exception. Upon initialization or reset, it sets the key value to `KEY_LOWER`. Each time it detects a rising edge of the input `start` it gives its current key value and yields a `finished` flag, indicating to the caller fsm that the current key is ready to be read, it then increments the key count by one. If the current key is greater than `KEY_UPPER` it yields the `terminated` flag, indicating to the caller (arcfour.sv) that all keys within [`KEY_LOWER`, `KEY_UPPER`] have been searched and rather than apply the RC4 algorithm again it should enter the `ARCFOUR_TERMINATED` state.


### 4. RAM Initializer FSM (ram_initializer.sv)
Performs the first part of keystream generation which involves setting the first 256 bytes in memory to their corresponding index value. In other words:
```
for i in range(255):
    S[i] = i
```


### 5. RAM Shuffle FSM (ram_shuffler.sv)
Performs the second part of keystream generation i.e. the following:

```
j = 0; 
for i in range(255):
    j = (j + S[i] + key[i % L])%256
    S[i], S[j] = S[j], S[i]
```

Once finished, the given keystream is now fully set inside memory block S.


### 6. Message Decryption FSM (decryptor.sv)
Takes the keystream and applies the final part of the RC4 encryption/decryption algorithm on the ciphertext, writing it into answer memory in the process:

```
i = 0, j=0
for k in [0, MESSAGE_LENGTH-1]:
    i = (i+1) % 256
    j = (j+S[i]) % 256
    S[i], S[j] = S[j], S[i]
    f = s[ (s[i]+s[j]) % 256 ]
    decrypted_output[k] = f ^ encrypted_input[k] 
```


This module also checks if each byte's value is in the set {97,...,122}∪{32} (i.e. checks that it is a letter or a blankspace character) and terminates prematurely yielding a cycle fail flag if the current byte value is outside of this set. If MESSAGE_LENGTH bytes are read with all being elements of this set then the FSM terminates yielding a cycle success flag, notifying the `arcfour` caller module that a valid key has been found.



<br></br>

# Nontrivialities


## Parallelization
Decryption cores are replicated `NUM_CORES` times during synthesis, this allows each core to operate over a key space of size equal to `KEY_MAX/NUM_CORES` instead of simply `KEY_MAX`; as such, parallel decryption is possible and the device is able to retrive keys at a greatly increased rate. Below is the relevant paralellization code. Note the pipelining for the `curr_key` and `core_ptr` acquisition logic, this was done to combat CL delays exceeding the clock period during high core counts (higher core counts lead to larger busses leading to longer lookup times during key acquisition, this issue is explained in more detail in the [Need For Pipelining section](#need-for-pipelining))

<details>
<summary>Parallelization code</summary>

```
    logic [NUM_CORES-1:0] s_wren_bus;                       //Bussin'
    logic [NUM_CORES-1:0][RAM_LENGTH-1:0] s_addr_bus;
    logic [NUM_CORES-1:0][RAM_WIDTH-1:0] s_in_bus;
    logic [NUM_CORES-1:0][RAM_WIDTH-1:0] s_out_bus;

    logic [NUM_CORES-1:0] a_wren_bus;
    logic [NUM_CORES-1:0][MESSAGE_LOG_LENGTH-1:0] a_addr_bus;
    logic [NUM_CORES-1:0][RAM_WIDTH-1:0] a_in_bus;

    logic [NUM_CORES-1:0][MESSAGE_LOG_LENGTH-1:0] k_addr_bus;
    logic [NUM_CORES-1:0][RAM_WIDTH-1:0] k_out_bus;

    logic [NUM_CORES-1:0] success_bus, registered_success_bus, term_bus;
    logic [LOG_NUM_CORES-1:0] core_ptr, mapped_core_ptr;
    logic [NUM_CORES-1:0][KEY_LENGTH*RAM_WIDTH-1:0] keys, curr_keys;

    
    logic success_sig, term_sig, kill_sig;        //Register these next
    assign success_sig = |success_bus;
    assign term_sig = &term_bus;
    assign kill_sig = success_sig || term_sig;


    bus_lock
    #(
        .BUS_WIDTH(NUM_CORES)
    ) success_lock (
        .clk(clk),
        .reset(reset_bit),
        .enable(start_bit),
        .inBus(success_bus),
        .outBus(registered_success_bus)
    );


    bus_lock
    #(
        .BUS_WIDTH(NUM_CORES*KEY_LENGTH*RAM_WIDTH)
    ) key_lock (
        .clk(clk),
        .reset(reset_bit),
        .enable(start_bit),
        .inBus(keys),
        .outBus(curr_keys)
    );


    first_bit_detector 
    #(
        .BUS_WIDTH(NUM_CORES),
        .LOG_BUS_WIDTH(LOG_NUM_CORES)
    ) core_detector (
        .bus(registered_success_bus), 
        .addr(mapped_core_ptr)
    );


    logic finish_sig_out, success_sig_out;
    always_ff @(posedge clk) begin
        if(reset_bit) core_ptr <= 0;
        else core_ptr <= mapped_core_ptr;
        finish_sig_out <= finish_bit;
        success_sig_out <= success_bit;
    end

    logic [KEY_LENGTH*RAM_WIDTH-1:0] curr_key;
    assign curr_key = keys[core_ptr];


    localparam k = KEY_MAX/NUM_CORES;
    genvar i;
    generate
        for(i = 0; i < NUM_CORES; i = i + 1) begin : core_generate
            arcfour #(
                .RAM_WIDTH(RAM_WIDTH),
                .RAM_LENGTH(RAM_LENGTH),
                .KEY_LENGTH(KEY_LENGTH),
                .KEY_UPPER(k * (i+1) - 1),
                .KEY_LOWER(k * i),
                .MESSAGE_LENGTH(MESSAGE_LENGTH),
                .MESSAGE_LOG_LENGTH(MESSAGE_LOG_LENGTH)
            ) RC
            (
                .clk(clk),
                .reset(reset_bit),
                .switch_key(switchKey),
                .start(start_bit),
                .sIn(s_in_bus[i]),
                .sAddr(s_addr_bus[i]),
                .sWren(s_wren_bus[i]),
                .sOut(s_out_bus[i]),
                .kAddr(k_addr_bus[i]),
                .kOut(k_out_bus[i]),
                .aAddr(a_addr_bus[i]),
                .aIn(a_in_bus[i]),
                .aWren(a_wren_bus[i]),
                .key_select(keySel),
                .succeeded(success_bus[i]),
                .outKey(keys[i]),
                .terminated(term_bus[i])
            );


            ramcore S (
                .address(s_addr_bus[i]),
                .clock(clk),
                .data(s_in_bus[i]),
                .wren(s_wren_bus[i]),
                .q(s_out_bus[i])
            );


            ramcore A(
                .address(a_addr_bus[i]),
                .clock(clk),
                .data(a_in_bus[i]),
                .wren(a_wren_bus[i])
            );


            romcore K(
                .address(k_addr_bus[i]),
                .clock(clk),
                .q(k_out_bus[i])
            );

        end
    endgenerate
```
</details>


## Memory management
The device currently uses on-chip memory accessed via an Altera Avalon Altsyncram interface (details in src/ip_blocks/). This was done for two reaons: 
1. Ease of development and testing with Quartus' in-system memory content editor 
2. Lower latency than SRAM or DDR3 due to the on-chip nature of the memory. 

This current implementation has some limits however:
1. Each decryption core requires a dedicated ROM block with the message inside and as such there is a large amount of memory overhead which scales with message size, this overhead could be resolved with the use of a single multi-port memory block in the future.
2. The ciphertext message is read-only and is set at compile-time. This means that every time a new message is to be tested the netlist has to be recompiled and the fpga has to be reprogrammed. This is both stupid and inefficient for very obvious reasons.

The next step here is to replace the ciphertext message memory with something that can be dynamically set during runtime and feed every core simultaneously. This also opens the door to something like the DE-1's Cortex A9 Hard Processor System (HPS) which could be used to control the FPGA and set new encrypted messages during system operation, thus allowing more advanced applications in the future such as RC4 encrypted packet processing. This system was designed with this in mind and as such, very little needs to be changed on the hardware side in order to make this happen, save for me actually having the time to do it.

Another thing to note is that all memory cores are instantiated outside of the decryption core module. This is intentional such as to allow for different memory interfaces in the future which could be beneficial as it seems that the current limiting factor regarding the number of cores comes down to the limited on-chip memory resources. This also streamlines HPS integration as very little needs to be changed in order to communicate with different memory systems more accessible to the HPS or even the HPS itself.



## Inter-FSM Communication 
A simple start-finish protocol is used for all inter-fsm communication. Each fsm is started by the rising edge of its respective start signal and starts any other sub-fsm by the same method. Upon termination a finish signal is yielded to the caller for one clock period and the fsm re-enters an idle state thereafter. With the exception of `key_generator`, all fsms have no recollection of the previous call after termination, this allows for minimal reset logic to be used outside of the explicit reset case.



## Need For Pipelining
During testing, an issue came up where the device's key acquisition seemed to work fine for a small numbers of cores but failed for larger numbers of cores. The issue was due to delays induced by two peices of combinational logic:
1. Identifying the index of the first high bit of `success_bus` and mapping that address to `core_ptr`
2. Using that `core_ptr` to access the appropriate key at that time via the `keys` bus

For high core counts both of these busses are quite large resulting in a very large CL delay that exceeds the clock period, thus inappropriate keys are returned. To combat this, pipelining was used where both `core_ptr` and `keys` are registered separately before being driven through the lookup CL. This allows a higher clock frequency to be used in the rest of the circuit.

