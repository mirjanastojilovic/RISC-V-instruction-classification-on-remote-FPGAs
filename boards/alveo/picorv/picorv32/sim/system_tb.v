/*
 Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
 Copyright 2023, School of Computer and Communication Sciences, EPFL.

 All rights reserved. Use of this source code is governed by a
 BSD-style license that can be found in the LICENSE.md file. 
 */

`timescale 1 ns / 1 ps

module system_tb;
    reg [31:0] cnt = 1'b0;
    reg clk_en = 1;
	reg clk = 1;
	always #5 clk = ~clk;
	
	always @(posedge clk) begin
	   cnt = cnt + 1;
	   if(cnt == 1000) begin
	       cnt = 0;
	       clk_en = ~clk_en;
	   end
	end

	reg resetn = 0;
	initial begin
		if ($test$plusargs("vcd")) begin
			$dumpfile("system.vcd");
			$dumpvars(0, system_tb);
		end
		repeat (100) @(posedge clk);
		resetn <= 1;
	end

	wire trap;
	wire [7:0] out_byte;
	wire out_byte_en;
        wire inst_mem_en;
        wire [3:0] inst_mem_wen;
        wire [11:0] inst_mem_addr;
        wire [31:0] inst_mem_data;

        assign inst_mem_en = 1'b0;
        assign inst_mem_wen = 4'b0000;
        assign inst_mem_addr = 12'b000000000000;
        assign inst_mem_data = 32'h00000000;

	picorv32_top uut (
		.clk           (clk          ),
		.resetn        (resetn       ),
                .clk_en        (clk_en       ),
		.trap          (trap         ),
                .inst_mem_clk  (clk          ),
                .inst_mem_en   (inst_mem_en  ),
                .inst_mem_wen  (inst_mem_wen ),
                .inst_mem_addr (inst_mem_addr),
                .inst_mem_data (inst_mem_data)
	);

	always @(posedge clk) begin
		if (resetn && out_byte_en) begin
			$write("%c", out_byte);
			$fflush;
		end
		if (resetn && trap) begin
			$finish;
		end
	end
endmodule
