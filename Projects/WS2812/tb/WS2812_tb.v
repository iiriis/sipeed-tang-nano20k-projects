module WS2812_tb;

    // Testbench signals
    reg clk;
    reg rst;
    reg set;
    reg [23:0] color;
    wire tx;

    // Instantiate the WS2812 module
    WS2812 uut (
        .clk(clk),
        .rst(rst),
        .set(set),
        .color(color),
        .tx(tx)
    );

    // Clock generation: 27 MHz clock, period = 37 ns
    always #18.5 clk = ~clk;

    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;      // Start with reset asserted
        set = 0;
        color = 24'h000000;  // Default color (black)

        // Reset the system
        #100 rst = 0;  // Release reset after 100 ns

        // Apply stimulus: Set a color and trigger the transmission
        #50 set = 1;
        color = 24'hFF0000;  // Red color
        #100 set = 0;

        // Wait for a few clock cycles
        #5000;

        // Apply another color
        #50 set = 1;
        color = 24'h00FF00;  // Green color
        #100 set = 0;

        // Wait again for a few clock cycles
        #5000;

        // End the simulation
        $finish;
    end

    // Monitor the tx signal
    initial begin
        $monitor("At time %t: tx = %b", $time, tx);
    end

    // Dump waveform for analysis in a simulator like GTKWave
    initial begin
        $dumpfile("WS2812_tb.vcd");
        $dumpvars(0, WS2812_tb);
    end

endmodule
