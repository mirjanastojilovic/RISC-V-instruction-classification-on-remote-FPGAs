/*
 Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
 Copyright 2023, School of Computer and Communication Sciences, EPFL.

 All rights reserved. Use of this source code is governed by a
 BSD-style license that can be found in the LICENSE.md file. 
 */

`timescale 1 ns / 1 ps

module picorv32_top (
	input            clk,
	input            resetn,
        input            clk_en,
        // DEBUG
	//output reg [7:0] out_byte,
	//output reg       out_byte_en,
        // Code memory interface
        input             inst_mem_clk,
        input             inst_mem_en,
        input       [3:0] inst_mem_wen,
        input      [12:0] inst_mem_addr,
        input      [31:0] inst_mem_data,
        // Data bus (Signals fetched instruction)
        output     [31:0] inst_fetched,
        output            inst_mem_rdy,
        output            inst_mem_vld,
        output            inst_mem_inst,
        output            dec_trigger,
        // TRAP signal
	output            trap
);

	wire mem_valid;
	wire mem_instr;
	wire mem_ready;
	wire [31:0] mem_addr;
	wire [31:0] mem_wdata;
	wire [3:0] mem_wstrb;
	wire [31:0] mem_rdata;
	reg  [31:0] inst_fetched_q;
        reg  resetn_q;
        wire inst_mem_rdy;
        wire inst_mem_vld;
        wire inst_mem_inst;
        wire dec_trigger;

	picorv32 #(
		.ENABLE_COUNTERS(0),
		.LATCHED_MEM_RDATA(1),
		.TWO_STAGE_SHIFT(0),
                .BARREL_SHIFTER(1),
		.CATCH_MISALIGN(0),
		.CATCH_ILLINSN(1)
	) picorv32_core (
		.clk          (clk         ),
		.resetn       (resetn_q    ),
		.clk_en       (clk_en      ),
		.trap         (trap        ),
		.mem_valid    (mem_valid   ),
		.mem_instr    (mem_instr   ),
		.mem_ready    (mem_ready   ),
		.mem_addr     (mem_addr    ),
		.mem_wdata    (mem_wdata   ),
		.mem_wstrb    (mem_wstrb   ),
		.mem_rdata    (mem_rdata   ),
                .instruction  (inst_fetched),
                .dec_trigger  (dec_trigger)
	);
	
	memory memory_module  (
		.clk          (clk           ),
		.clk_en       (clk_en        ),
		.reset_n      (resetn_q      ),
		.mem_valid    (mem_valid     ),
		.mem_instr    (mem_instr     ),
		.mem_ready    (mem_ready     ),
		.mem_addr     (mem_addr[14:2]),
		.mem_wdata    (mem_wdata     ),
		.mem_wstrb    (mem_wstrb     ),
		.mem_rdata    (mem_rdata     ),
                .inst_mem_clk (inst_mem_clk  ),
                .inst_mem_en  (inst_mem_en   ),
                .inst_mem_wen (inst_mem_wen  ),
                .inst_mem_addr(inst_mem_addr ),
                .inst_mem_data(inst_mem_data )
	);

        assign inst_mem_rdy = mem_ready;
        assign inst_mem_vld = mem_valid;
        assign inst_mem_inst = mem_instr;

        //always @(posedge clk) begin
        //  if(mem_instr && mem_valid && mem_ready) begin
        //    inst_fetched_q = mem_rdata;
        //  end
        //end
        //assign inst_fetched = inst_fetched_q;

        always @(posedge clk) begin
          resetn_q <= resetn;
        end

        // DEBUG
	//always @(posedge clk) begin
        //    out_byte_en <= 0;
        //    
        //    if (mem_valid && 
        //        !mem_ready && 
        //        |mem_wstrb && 
        //        mem_addr == 32'h1000_0000) begin
        //        out_byte_en <= 1;
        //        out_byte <= mem_wdata;
        //    end
        //    
        //end

endmodule
