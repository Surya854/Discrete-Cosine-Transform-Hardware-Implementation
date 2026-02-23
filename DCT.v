
`timescale 1ns / 1ps

module DCT(
    input clk,
    input reset,
    input start,
    input [7:0] INPUT_A,
    input [7:0] INPUT_B,
    output reg signed [23:0] OUTPUT_A, 
    output reg signed [23:0] OUTPUT_B,
    output reg [3:0] INDEX_A,
    output reg [3:0] INDEX_B,
    output reg output_en
);

    localparam signed [15:0] C_PI_4   = 16'd362;
    localparam signed [15:0] C_PI_8   = 16'd473;
    localparam signed [15:0] C_3PI_8  = 16'd196;
    localparam signed [15:0] C_PI_16  = 16'd502;
    localparam signed [15:0] C_3PI_16 = 16'd426;
    localparam signed [15:0] C_5PI_16 = 16'd284;
    localparam signed [15:0] C_7PI_16 = 16'd100;
 
    localparam IDLE      = 3'd0;
    localparam LOAD      = 3'd1;
    localparam COMPUTE_1 = 3'd2;
    localparam COMPUTE_2 = 3'd3;
    localparam COMPUTE_3 = 3'd4;
    localparam compute_4 = 3'd5;
    localparam OUTPUT    = 3'd6;
    
    reg [2:0] state;
    reg [3:0] load_counter;
    reg [3:0] out_counter;

    reg signed [23:0] x_reg [0:15];
    reg signed [23:0] stage1_reg [0:15];
    reg signed [23:0] stage2_reg [0:15];
    reg signed [23:0] stage3_reg [0:15];
    reg signed [23:0] final_out_reg [0:15];
    reg signed [23:0] int1;
    reg signed [23:0] int2;
    integer i;

    wire [3:0] out_map [0:15];
    assign out_map[0]=0;  assign out_map[1]=8;   assign out_map[2]=4;   assign out_map[3]=12;
    assign out_map[4]=2;  assign out_map[5]=6;   assign out_map[6]=10;  assign out_map[7]=14;
    assign out_map[8]=1;  assign out_map[9]=3;   assign out_map[10]=5;  assign out_map[11]=7;
    assign out_map[12]=9; assign out_map[13]=11; assign out_map[14]=13; assign out_map[15]=15;


    function signed [23:0] mult_q8;
        input signed [23:0] val;
        input signed [15:0] coeff;
        reg signed [39:0] temp;
        begin
            temp = val * coeff;
            mult_q8 = temp[31:8]; 
        end
    endfunction

    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            load_counter <= 0;
            out_counter <= 0;
            output_en <= 0;
            OUTPUT_A <= 0; OUTPUT_B <= 0;
            INDEX_A <= 0; INDEX_B <= 0;
        end else begin
            case (state)
                IDLE: begin
                    output_en <= 0;
                    load_counter <= 0;
                    if (start) begin

                        x_reg[0]  <= {8'b0, INPUT_A, 8'b0}; 
                        x_reg[15] <= {8'b0, INPUT_B, 8'b0};
                        load_counter <= 1;
                        state <= LOAD;
                    end
                end
                
                LOAD: begin
                    if (load_counter < 8) begin
                        x_reg[load_counter] <= {8'b0, INPUT_A, 8'b0};
                        x_reg[15 - load_counter] <= {8'b0, INPUT_B, 8'b0};
                        load_counter <= load_counter + 1;
                    end else begin
                        state <= COMPUTE_1; 
                    end
                end
                
                COMPUTE_1: begin

                    for (i = 0; i < 8; i = i + 1) begin
                        stage1_reg[i]     <= x_reg[i] + x_reg[15 - i];
                        stage1_reg[8+i] <= x_reg[i] - x_reg[15 - i];
                    end
                    state <= COMPUTE_2;
                end
                
                COMPUTE_2: begin

                    for (i = 0; i < 4; i = i + 1) begin
                        stage2_reg[i]     <= stage1_reg[i] + stage1_reg[7 - i];
                        stage2_reg[4+i] <= stage1_reg[i] - stage1_reg[7 - i];
                    end
                    
                    for (i = 0; i < 4; i = i + 1) begin
                       
                        int1 = stage1_reg[8 + i] - stage1_reg[15 - i];
                        int2 = mult_q8(stage1_reg[12 + i], C_PI_4);
                        
                        stage2_reg[8 + i]  <= int1 + int2; 
                        stage2_reg[12 + i] <= int1 - int2;
                    end
                    state <= COMPUTE_3;
                end
                
                COMPUTE_3: begin

                    stage3_reg[0] <= stage2_reg[0] + stage2_reg[3];
                    stage3_reg[3] <= stage2_reg[0] - stage2_reg[3];
                    stage3_reg[1] <= stage2_reg[1] + stage2_reg[2];
                    stage3_reg[2] <= stage2_reg[1] - stage2_reg[2];
                    
                    for (i = 0; i < 2; i = i + 1) begin
                        int1 = stage2_reg[4 + i] - stage2_reg[7 - i];
                        int2 = mult_q8(stage2_reg[6 + i], C_PI_4);
                        stage3_reg[4 + i] <= int1 + int2;
                        stage3_reg[6 + i] <= int1 - int2;
                    end

                    for (i=0; i<2; i=i+1) begin
                        int1 = stage2_reg[8 + i] - stage2_reg[11 - i];
                        int2 = mult_q8(stage2_reg[10 + i], C_PI_8);
                        stage3_reg[8 + i] <= int1 + int2;
                        stage3_reg[10 + i] <= int1 - int2;
                    end

                    for (i=0; i<2; i=i+1) begin
                        int1 = stage2_reg[12 + i] - stage2_reg[15 - i];
                        int2 = mult_q8(stage2_reg[14 + i], C_3PI_8);
                        stage3_reg[12 + i] <= int1 + int2;
                        stage3_reg[14 + i] <= int1 - int2;
                    end
                    state <= compute_4;
                    out_counter <= 0;
                end
                
                compute_4: begin
                
                final_out_reg[0] <= stage3_reg[0] + stage3_reg[1];
                final_out_reg[1] <= stage3_reg[0] - stage3_reg[1];
                int1 = stage3_reg[3] - stage3_reg[2];
                int2 = mult_q8(stage3_reg[2], C_PI_4);
                final_out_reg[2] <= int1 + int2;
                final_out_reg[3] <= int1-int2;
                int1 = stage3_reg[4]-stage3_reg[5];
                int2 = mult_q8(stage3_reg[5],C_PI_8);
                final_out_reg[4] <= int1 + int2;
                final_out_reg[5] <= int1 - int2;
                int1 = stage3_reg[6]-stage3_reg[7];
                int2 = mult_q8(stage3_reg[7],C_3PI_8);
                final_out_reg[6] <= int1 + int2;
                final_out_reg[7] <= int1 - int2;
                int1 = stage3_reg[8]-stage3_reg[9];
                int2 = mult_q8(stage3_reg[9],C_PI_16);
                final_out_reg[8] <= int1 + int2;
                final_out_reg[9] <= int1 - int2;
                int1 = stage3_reg[10]-stage3_reg[11];
                int2 = mult_q8(stage3_reg[11],C_7PI_16);
                final_out_reg[10] <= int1 + int2;
                final_out_reg[11] <= int1 - int2;
                int1 = stage3_reg[12]-stage3_reg[13];
                int2 = mult_q8(stage3_reg[13],C_3PI_16);
                final_out_reg[12] <= int1 + int2;
                final_out_reg[13] <= int1 - int2;
                int1 = stage3_reg[14]-stage3_reg[15];
                int2 = mult_q8(stage3_reg[15],C_5PI_16);
                final_out_reg[14] <= int1 + int2;
                final_out_reg[15] <= int1 - int2;
                state <= OUTPUT;
                end
                OUTPUT: begin
                    if (out_counter < 8) begin
                        output_en <= 1'b1;
                        
                        OUTPUT_A <= final_out_reg[out_counter * 2];
                        INDEX_A  <= out_map[out_counter * 2];
                        
                        OUTPUT_B <= final_out_reg[out_counter * 2 + 1];
                        INDEX_B  <= out_map[out_counter * 2 + 1];
                        
                        out_counter <= out_counter + 1;
                    end else begin
                        output_en <= 1'b0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule
