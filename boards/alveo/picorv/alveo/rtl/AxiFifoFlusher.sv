/*
 Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
 Copyright 2023, School of Computer and Communication Sciences, EPFL.

 All rights reserved. Use of this source code is governed by a
 BSD-style license that can be found in the LICENSE.md file. 
 */

module AxiFifoFlusher #(
    DATA_WIDTH_IN = 32,
    DATA_WIDTH_OUT = 32
) (
    input wire [63:0]                     base_ptr,

    // BRAM side interfaces
    output wire                           fifo_rd_en,
    input wire [DATA_WIDTH_IN - 1 : 0]    fifo_dout,
    input wire                            fifo_empty,
    input wire                            fifo_data_valid,
    // control
    input wire                            start_dump,
    output wire                           dump_idle,

    // axi master write interface
    input wire                            aclk,
    input wire                            aresetn,

    output wire [63:0]                    awaddr,
    output wire [7:0]                     awlen,
    output wire [2:0]                     awsize,
    output wire                           awvalid,
    input wire                            awready,

    output wire [DATA_WIDTH_OUT-1:0]     wdata,
    output wire [DATA_WIDTH_OUT/8-1:0]   wstrb,
    output wire                           wvalid,
    output wire                           wlast,
    input wire                            wready,

    input wire [1:0]                      bresp,
    input wire                            bvalid,
    output wire                           bready


);

    // assign byte_addr = addra << ADDRESS_OFFSET;
    logic [63 : 0] byte_addr;
    localparam NUM_BYTES = DATA_WIDTH_OUT / 8;
    localparam ADDRESS_OFFSET = $clog2(NUM_BYTES);

    typedef enum logic[3:0] { IDLE, ACCESS_FIFO, WAIT_FIFO, PUSH_ADDR, PUSH_DATA, WAIT_RESP, CHECK} StateType;



    StateType pstate = IDLE;
    StateType nstate;



    always_ff @(posedge aclk) begin
        if (~aresetn) begin
            pstate <= IDLE;
            byte_addr <= base_ptr;
        end else begin
            pstate <= nstate;
            if (pstate == CHECK) begin
                byte_addr <= byte_addr + NUM_BYTES;
            end
            else if(pstate == IDLE) begin
                byte_addr <= base_ptr;
            end
        end
    end


    always_comb begin

        nstate = IDLE;

        case (pstate)
            IDLE: if (start_dump) nstate = ACCESS_FIFO; else nstate = IDLE;
            ACCESS_FIFO:
                nstate = WAIT_FIFO;
            WAIT_FIFO:
                if(fifo_data_valid == 1'b1)
                    nstate = PUSH_ADDR;
                else
                    nstate = WAIT_FIFO;
            PUSH_ADDR:
                if (awready)
                    nstate = PUSH_DATA;
                else
                    nstate = PUSH_ADDR;
            PUSH_DATA:
                if (wready)
                    nstate = WAIT_RESP;
                else
                    nstate = PUSH_DATA;
            WAIT_RESP:
                if (bvalid) begin
                    nstate = CHECK;
                end else begin
                    nstate = WAIT_RESP;
                end
            CHECK:
                if (fifo_empty == 1'b1)
                    nstate = IDLE;
                else
                    nstate = ACCESS_FIFO;
            default:
                nstate = IDLE;
        endcase

    end

    //assign word_addr = byte_addr >> ADDRESS_OFFSET;
    assign fifo_rd_en = (pstate == ACCESS_FIFO);

    assign dump_idle = (pstate == IDLE);

    assign awaddr = byte_addr;
    assign awvalid = (pstate == PUSH_ADDR);
    assign awsize = ADDRESS_OFFSET;
    assign awlen = 0;

    assign bready = 1'b1;

    assign wvalid = (pstate == PUSH_DATA);
    assign wlast = (pstate == PUSH_DATA);
    assign wstrb = {NUM_BYTES{1'b1}};
    assign wdata = {{DATA_WIDTH_OUT-DATA_WIDTH_IN{1'b0}},fifo_dout};

endmodule
