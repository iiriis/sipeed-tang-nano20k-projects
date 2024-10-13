module top (
    input wire btn2,
    input wire clk,
    input wire btn1,
    input wire uartRx,
    output wire uartTx,
    output wire [5:0] led 
);

reg [7:0] data;
reg [5:0] ascii_counter;
reg [23:0] micros;
reg [7:0] rx_data; // Keep this as reg to be assigned in always block

always @(posedge btn1) begin

    if (btn2) begin
        ascii_counter <= 0;
        data <= 0;
    end else begin
            data <= 65 + ascii_counter;
            ascii_counter <= ascii_counter + 1;

            if (ascii_counter == 25) begin
                ascii_counter <= 0;
            end
    end

end

// always @(posedge clk ) begin
//     micros <= micros + 1;
//     if(micros == 2330)begin
//         micros <= 0;
//         data <= 65 + ascii_counter;
//         ascii_counter <= ascii_counter + 1;

//         if (ascii_counter == 25) begin
//             ascii_counter <= 0;
//         end
//     end
// end

localparam clock = 27000000;
localparam baud = 115200;

wire [5:0] not_led;

assign led = ~(not_led);

UART uart (
    .rst(btn2), 
    .clk(clk), 
    .tx_buffer(data), 
    .baud_div(clock/baud - 1), 
    .TX(uartTx),
    .RX(uartRx),
    .tx_busy(),
    .rx_buffer(not_led) // Keep as reg in UART module for assignment
);

endmodule


module UART (
    input wire rst,
    input wire clk,
    input wire [7:0] tx_buffer,
    input wire [15:0] baud_div,
    input wire RX,
    output reg [7:0] rx_buffer,
    output reg rx_int,
    output reg TX,          
    output reg tx_busy
);

reg [16:0] baud_counter_tx;
reg [7:0] last_tx_buffer;

reg [1:0] tx_state;
localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;

reg [3:0] bit_indexer_tx;

always @(posedge clk or posedge rst) begin
    if (rst == 1) begin
        tx_state <= IDLE;
        last_tx_buffer <= 0;
        baud_counter_tx <= 0;
        bit_indexer_tx <= 0;
        tx_busy <= 0;
        TX <= 1; // Idle state for TX line
    end else begin
        case (tx_state)
            IDLE: begin
                
                if ((tx_buffer != last_tx_buffer) && (tx_busy == 0)) begin
                    tx_state <= START;
                    last_tx_buffer <= tx_buffer;
                    tx_busy <= 1; // transmission begins

                    TX <= 0; // Start bit
                    bit_indexer_tx <= 0;
                    
                end
            end

            START: begin
                if (baud_counter_tx == baud_div) begin
                    baud_counter_tx <= 0;
                    tx_state <= DATA;

                    TX <= last_tx_buffer[bit_indexer_tx];
                    bit_indexer_tx <= 1;
                    

                end else begin
                    baud_counter_tx <= baud_counter_tx + 1;
                end
            end

            DATA: begin
                if (baud_counter_tx == baud_div) begin
                    baud_counter_tx <= 0;

                    if (bit_indexer_tx < 8) begin
                        TX <= last_tx_buffer[bit_indexer_tx];
                        bit_indexer_tx <= bit_indexer_tx + 1;
                    end else begin
                        TX <= 1; // Stop bit
                        tx_state <= STOP;
                    end

                end else begin
                    baud_counter_tx <= baud_counter_tx + 1;
                end
            end

            STOP: begin
                if (baud_counter_tx == baud_div) begin
                    baud_counter_tx <= 0;
                    tx_state <= IDLE;

                    tx_busy <= 0; // Transmission done
                end else begin
                    baud_counter_tx <= baud_counter_tx + 1;
                end
            end
        endcase
    end
end


reg [16:0] baud_counter_rx;

reg [1:0] rx_state;
reg [7:0] rx_shift_data;
reg [3:0] bit_indexer_rx;


always @(posedge clk  or posedge rst) begin

if (rst == 1) begin
    rx_state <= IDLE;
    baud_counter_rx <= 0;
    bit_indexer_rx <= 0;
    rx_shift_data <= 0;
    rx_int <= 0;
    rx_buffer <= 0;
end else begin

    case (rx_state)
        IDLE : begin
            if(RX == 0) begin
                rx_state <= START;
                baud_counter_rx <= 0;
            end
        end

        START : begin
            baud_counter_rx <= baud_counter_rx + 1;

                if(baud_counter_rx == (baud_div >> 1)) begin // go half way (/2) and sample at the middle of the start bit
                    baud_counter_rx <= 0;
                    if (RX == 0) begin                  // if still the bit is low, valid start bit
                        rx_state <= DATA;
                        bit_indexer_rx <= 4'h0;
                    end
                    else
                        rx_state <= IDLE;               // invalid RX state goes back to IDLE
                end
        end
        DATA : begin
            baud_counter_rx <= baud_counter_rx + 1;
            
            if(baud_counter_rx == baud_div) begin   // this time look for the full length of baud div, which will result into the mid of first bit
                rx_shift_data[bit_indexer_rx] <= RX;
                bit_indexer_rx <= bit_indexer_rx + 1;
                baud_counter_rx <= 0;

                if (bit_indexer_rx == 8) begin
                    rx_state <= STOP;
                    rx_buffer <= rx_shift_data;
                end
            end
        end

        STOP : begin
            if(RX == 0) begin           // invalid rx data
                rx_state <= IDLE;
                rx_shift_data <= 0;
                rx_buffer <= 0;
            end else begin
                rx_int <= 1;    // assert the int signal
                baud_counter_rx <= baud_counter_rx + 1;
                
                if(baud_counter_rx == (baud_div >> 1)) begin
                    rx_int <= 0; // dessert the INT signal
                    rx_state <= IDLE;
                end
            end
        end

    endcase
end
    
end

endmodule







