`timescale 1ns / 1ps

module UART_tb();

    // Testbench signals
    reg clk;
    reg rst;
    reg [7:0] tx_buffer;
    reg [15:0] baud_div;
    wire TX;
    wire tx_busy;

    // Instantiate the UART module
    UART uart_inst (
        .rst(rst),
        .clk(clk),
        .tx_buffer(tx_buffer),
        .baud_div(baud_div),
        .TX(TX),
        .tx_busy(tx_busy)
    );

    // Clock generation (27 MHz clock)
    always #18.35 clk = ~clk;  // 27 MHz clock, period = 37 ns

    initial begin
        // Initialize signals
        clk = 0;
        rst = 0;
        tx_buffer = 8'h00;
        baud_div = 8'hE9;  // Baud divider for 115200 baud at 27 MHz clock

        // Apply reset
        rst = 1;
        #100;  // Hold reset for 100ns
        rst = 0;

        // Test case: Send 0x55 (binary 01010101) over UART
        #50;  // Wait for a few clock cycles after reset
        tx_buffer = 8'h55;

        // Wait until transmission starts and finishes
        wait (tx_busy == 1);
        $display("Transmission started...");
        
        wait (tx_busy == 0);
        $display("Transmission completed for 0x55");

        // Test case: Send 0xAA (binary 10101010) over UART
        tx_buffer = 8'hAA;
        
        wait (tx_busy == 1);
        $display("Transmission started for 0xAA...");
        
        wait (tx_busy == 0);
        $display("Transmission completed for 0xAA");

        // Test case: Send 0xFF (binary 11111111) over UART
        tx_buffer = 8'h7F;
        
        wait (tx_busy == 1);
        $display("Transmission started for 0x7F...");
        
        wait (tx_busy == 0);
        $display("Transmission completed for 0x7F");

        // Test completed
        $display("Testbench completed.");
        $finish;
    end

    // Dump signals for waveform viewing
    initial begin
        $dumpfile("uart_waveform.vcd");  // Create dump file for GTKWave
        $dumpvars(0, UART_tb);           // Dump all signals
    end

endmodule
