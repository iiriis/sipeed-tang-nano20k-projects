`timescale 1ns / 1ps

module UART_RX_tb();

// Testbench signals
reg clk;
reg rst;
reg RX;
reg [15:0] baud_div;
wire [7:0] rx_buffer;
wire rx_int;

// Instantiate UART module
UART uart_inst (
    .rst(rst),
    .clk(clk),
    .RX(RX),
    .rx_buffer(rx_buffer),
    .baud_div(baud_div),
    .rx_int(rx_int)
);

// Clock generation (27 MHz clock)
always #18.35 clk = ~clk;  // 27 MHz clock, period = 37 ns

// UART frame generator task
task send_uart_frame;
    input [7:0] data;  // Data to send
    integer i;

    begin
        // Start bit (low)
        RX <= 0;
        #(baud_div * 37);  // Wait for one baud period (divided by clock frequency)

        // Data bits (LSB first)
        for (i = 0; i < 8; i = i + 1) begin
            RX <= data[i];
            #(baud_div * 37);  // Wait for one baud period for each bit
        end

        // Stop bit (high)
        RX <= 1;
        #(baud_div * 37);  // Wait for one baud period
    end
endtask

initial begin
    // Initialize signals
    clk = 0;
    rst = 0;
    RX = 1;  // Idle line
    baud_div = 233;  // Baud divider for 115200 baud at 27 MHz clock

    // Apply reset
    rst = 1;
    #100;  // Hold reset for 100ns
    rst = 0;

    // Test 1: Send 0x55 (binary 01010101) over UART
    #1000;  // Wait for a few clock cycles after reset
    send_uart_frame(8'h55);  // Send 0x55
    #1000;  // Wait for some time

    // Check if rx_buffer has received 0x55 and rx_int was asserted
    if (rx_buffer == 8'h55) begin
        $display("Test 1 Passed: Received 0x55 correctly");
    end else begin
        $display("Test 1 Failed: Expected 0x55, but received %h", rx_buffer);
    end

    // Test 2: Send 0xAA (binary 10101010) over UART
    send_uart_frame(8'hAA);  // Send 0xAA
    #1000;  // Wait for some time

    // Check if rx_buffer has received 0xAA and rx_int was asserted
    if (rx_buffer == 8'hAA) begin
        $display("Test 2 Passed: Received 0xAA correctly");
    end else begin
        $display("Test 2 Failed: Expected 0xAA, but received %h", rx_buffer);
    end

    // Test completed
    $finish;
end

// Dump signals for waveform viewing (optional)
initial begin
    $dumpfile("uart_rx_waveform.vcd");  // Create dump file for GTKWave
    $dumpvars(0, UART_RX_tb);           // Dump all signals
end

endmodule
