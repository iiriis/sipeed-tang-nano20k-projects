module top (
    input wire btn1,
    input wire btn2,
    output wire [5:0] led
);

    // Intermediate signal to capture the shifted LED values
    wire [5:0] shifted_led;

    reg clock_div;
    integer count;

    // Clock divider logic
    always @(posedge btn2) begin
        count <= count + 1;
        if (count == 10500000) begin
            clock_div <= ~clock_div;
            count <= 0;
        end
    end

    LFSR lfsr1(
        .DATA(shifted_led),
        .clk(clock_div),
        .reset(btn1)
    );

    // Invert the shifted LED signals for active low
    assign led = ~shifted_led;

endmodule

module shiftReg (
    input wire D,
    input wire clk,
    output reg [5:0] out
);

    always @(posedge clk) begin
        // Shift register logic with raw D input
        out <= {out[4:0], D | out[5]};
    end

endmodule


module LFSR (
    output reg [5:0] DATA,
    input wire clk,
    input wire reset
);

initial begin
    
end

always @(posedge clk or posedge reset) begin

    if (reset == 1) begin
        DATA <= 6'b101101;
    end else begin
        DATA[0] <= DATA[5];
        DATA[1] <= DATA[0] ^ DATA [5];
        DATA[2] <= DATA[1] ^ DATA [5];
        DATA[3] <= DATA[2];
        DATA[4] <= DATA[3];
        DATA[5] <= DATA[4] ^ DATA [5];
    end
end
    
endmodule