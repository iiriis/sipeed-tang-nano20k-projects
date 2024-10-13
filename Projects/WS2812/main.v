module top (
    input wire clk,
    output wire led0,
    input wire btn2,
    output wire WS2812_TX
);

reg [24:0] time_counter;
reg rdy;

localparam clk_freq = 27000000;
localparam t_ms = 500;
localparam t_ms_ticks = (clk_freq / 1000) * t_ms;

wire [23:0] color;

reg [31:0] freq_div;
reg [31:0] compare;

// Time counter logic to trigger `rdy` signal
always @(posedge clk or posedge btn2) begin
    if (btn2) begin
        time_counter <= 0;  // Reset counter on `btn2`
        rdy <= 0;           // Reset `rdy` when `btn2` is pressed
        freq_div <= 1000;
        compare <= 0;
    end else begin
        time_counter <= time_counter + 1;

        if(time_counter & 16'hffff) begin
            compare <= compare + 1;
            if (compare == 1000) begin
                compare <= 0;
            end
        end

        if (time_counter == t_ms_ticks) begin
            rdy <= 1;   // Set `rdy` high

        end else if (time_counter == t_ms_ticks + 32) begin
            rdy <= 0;   // Reset `rdy` and counter
            time_counter <= 0;
        end
    end
end

// WS2812 instantiation
WS2812 ws2812 (
    .clk(clk),
    .color(color),
    .tx(WS2812_TX),
    .rst(btn2),
    .set(rdy)
);

// LFSR instantiation
LFSR lfsr (
    .clk(rdy),
    .DATA(color),
    .reset(btn2)
);


PWM pwm (
    .clk(clk),
    .op_pin(led0),
    .freq_div(freq_div),
    .compare(compare),
    .rst(btn2)
    );

endmodule

module WS2812 (
    input wire clk,
    input wire [23:0] color,  // Proper input declaration
    output reg tx,
    input wire rst,
    input wire set
);

parameter clk_freq = 27000000;

// Timing parameters in ticks
parameter T0_H_ticks = 9;            // 350ns
parameter T0_L_ticks = 9 + 22;       // 800ns
parameter T1_H_ticks = 19;           // 700ns
parameter T1_L_ticks = 19 + 16;      // 600ns
parameter RFSH_ticks = 16;           // 50us

reg [5:0] bit_indexer;
reg [5:0] tick_counter;
reg [2:0] state;

parameter IDLE = 0, TX = 1, RFSH = 2;

always @(posedge clk) begin
    if (rst) begin
        bit_indexer <= 0;
        tick_counter <= 0;
        state <= IDLE;               // Ensure state initializes to IDLE
        tx <= 0;
    end else begin
        case (state)
            IDLE: begin
                tx <= 0;
                bit_indexer <= 0;
                tick_counter <= 0;
                if (set) begin
                    state <= TX;      // Start transmission when 'set' is high
                end
            end

            TX: begin
                if (color[23 - bit_indexer] == 0) begin  // Check current bit (MSB first)
                    tick_counter <= tick_counter + 1;
                    if (tick_counter < T0_H_ticks) begin
                        tx <= 1;      // High for T0_H_ticks
                    end else if (tick_counter < T0_L_ticks) begin
                        tx <= 0;      // Low for T0_L_ticks
                    end else begin
                        tick_counter <= 0;
                        bit_indexer <= bit_indexer + 1; // Move to the next bit
                        tx <= 1;
                    end
                end else begin
                    tick_counter <= tick_counter + 1;
                    if (tick_counter < T1_H_ticks) begin
                        tx <= 1;      // High for T1_H_ticks
                    end else if (tick_counter < T1_L_ticks) begin
                        tx <= 0;      // Low for T1_L_ticks
                    end else begin
                        tick_counter <= 0;
                        bit_indexer <= bit_indexer + 1; // Move to the next bit
                        tx <= 1;
                    end
                end

                if (bit_indexer == 24) begin
                    state <= RFSH;    // Move to refresh state after 24 bits
                end
            end

            RFSH: begin
                tx <= 0;              // Keep the line low
                tick_counter <= tick_counter + 1;
                if (tick_counter == RFSH_ticks) begin
                    tick_counter <= 0;
                    state <= IDLE;    // Return to idle after refresh time
                end
            end
        endcase
    end
end

endmodule


module LFSR (
    output reg [23:0] DATA,
    input wire clk,
    input wire reset
);


always @(posedge clk or posedge reset) begin
    if (reset == 1) begin
        time_counter <= 0;
        DATA <= 24'b101101001011010010110100;
    end else begin
        DATA[0]  <= DATA[23];  
        DATA[1]  <= DATA[0] ^ DATA[23];
        DATA[2]  <= DATA[1];
        DATA[3]  <= DATA[2];
        DATA[4]  <= DATA[3];
        DATA[5]  <= DATA[4];
        DATA[6]  <= DATA[5] ^ DATA[23];
        DATA[7]  <= DATA[6] ^ DATA[23];
        DATA[8]  <= DATA[7];
        DATA[9]  <= DATA[8] ^ DATA[23];
        DATA[10] <= DATA[9];
        DATA[11] <= DATA[10];
        DATA[12] <= DATA[11];
        DATA[13] <= DATA[12];
        DATA[14] <= DATA[13];
        DATA[15] <= DATA[14];
        DATA[16] <= DATA[15];
        DATA[17] <= DATA[16] ^ DATA[23];  // Feedback XOR at tap 17
        DATA[18] <= DATA[17];
        DATA[19] <= DATA[18] ^ DATA[23];
        DATA[20] <= DATA[19];
        DATA[21] <= DATA[20];
        DATA[22] <= DATA[21] ^ DATA[23];  // Feedback XOR at tap 22
        DATA[23] <= DATA[22] ^ DATA[23];  // Feedback XOR at tap 23
    end
end
    
endmodule

module PWM (
    input wire clk,
    input wire [31:0] freq_div,
    input wire [31:0] compare,
    output reg op_pin,
    input wire rst
);

reg [31:0] tick_counter;

always @(posedge clk ) begin
    if(rst)
        tick_counter <= 0;
    tick_counter <= tick_counter + 1;
    if (tick_counter < compare) begin
        op_pin <= 1;
    end else if (tick_counter < freq_div) begin
        op_pin <= 0;
    end else begin
        tick_counter <= 0;
    end
end
    
endmodule