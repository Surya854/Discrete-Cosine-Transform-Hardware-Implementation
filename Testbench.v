`timescale 1ns / 1ps

module tb_DCT;

    // --- Inputs ---
    reg clk;
    reg reset;
    reg start;
    reg [7:0] INPUT_A;
    reg [7:0] INPUT_B;

    // --- Outputs ---
    wire signed [23:0] OUTPUT_A;
    wire signed [23:0] OUTPUT_B;
    wire [3:0] INDEX_A;
    wire [3:0] INDEX_B;
    wire output_en;

    DCT uut (
        .clk(clk), 
        .reset(reset), 
        .start(start), 
        .INPUT_A(INPUT_A), 
        .INPUT_B(INPUT_B), 
        .OUTPUT_A(OUTPUT_A), 
        .OUTPUT_B(OUTPUT_B), 
        .INDEX_A(INDEX_A), 
        .INDEX_B(INDEX_B), 
        .output_en(output_en)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end

    reg [7:0] test_data [0:15];
    integer i;

    initial begin

        test_data[0]  = 8'd1; test_data[1]  = 8'd3; test_data[2]  = 8'd5; test_data[3]  = 8'd7;
        test_data[4]  = 8'd9; test_data[5]  = 8'd17; test_data[6]  = 8'd19; test_data[7]  = 8'd21;
        test_data[8]  = 8'd22;   test_data[9]  = 8'd18;   test_data[10] = 8'd18;   test_data[11] = 8'd16;
        test_data[12] = 8'd8;   test_data[13] = 8'd6;   test_data[14] = 8'd4;   test_data[15] = 8'd2;

        reset = 1;
        start = 0;
        INPUT_A = 0;
        INPUT_B = 0;

        #100;
        reset = 0;
        #20;

        @(negedge clk); 
        start = 1;
        INPUT_A = test_data[0];
        INPUT_B = test_data[15];
        
        @(negedge clk);
        start = 0; 
        INPUT_A = test_data[1];
        INPUT_B = test_data[14];
        
        for (i = 2; i < 8; i = i + 1) begin
            @(negedge clk);
          INPUT_A = test_data[i];
          INPUT_B = test_data[15 - i];
       end

        wait (output_en == 1'b1);
        wait (output_en == 1'b0); 
        #25;
        $display("========================================");
        $display("          SIMULATION COMPLETE           ");
        $display("========================================");
        $finish;
    end

    real real_out_A, real_out_B;
    
    always @(posedge clk) begin
        if (output_en) begin
             
            real_out_A = $itor(OUTPUT_A) / 256.0;
            real_out_B = $itor(OUTPUT_B) / 256.0;
            
            $display("Time: %0t ns | X[%2d] = %9.4f  |  X[%2d] = %9.4f", 
                     $time, INDEX_A, real_out_A, INDEX_B, real_out_B);
        end
    end

endmodule
