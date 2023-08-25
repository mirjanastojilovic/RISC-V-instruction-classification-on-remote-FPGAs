/*-------------------------------------------------------------------------
 AES cryptographic module for FPGA on SASEBO-GIII
 
 File name   : chip_sasebo_giii_aes.v
 Version     : 1.0
 Created     : APR/02/2012
 Last update : APR/25/2013
 Desgined by : Toshihiro Katashita
 
 
 Copyright (C) 2012,2013 AIST
 
 By using this code, you agree to the following terms and conditions.
 
 This code is copyrighted by AIST ("us").
 
 Permission is hereby granted to copy, reproduce, redistribute or
 otherwise use this code as long as: there is no monetary profit gained
 specifically from the use or reproduction of this code, it is not sold,
 rented, traded or otherwise marketed, and this copyright notice is
 included prominently in any copy made.
 
 We shall not be liable for any damages, including without limitation
 direct, indirect, incidental, special or consequential damages arising
 from the use of this code.
 
 When you publish any results arising from the use of this code, we will
 appreciate it if you can cite our paper.
 (http://www.risec.aist.go.jp/project/sasebo/)
 -------------------------------------------------------------------------*/


//================================================ CHIP_SASEBO_GIII_AES
module CHIP_SASEBO_GIII_AES
  (// Local bus for GII
   lbus_di_a, lbus_do, lbus_wrn, lbus_rdn,
   lbus_clkn, lbus_rstn,

   // GPIO and LED
   gpio_startn, gpio_endn, gpio_exec, led,

   // Enable for the 200 MHz Kintex-7 clock
   osc_en_b,
   
   // 200 MHz Kintex-7 clock
   clk_kintex);
   
   //------------------------------------------------
   // Local bus for GII
   input [15:0]  lbus_di_a;
   output [15:0] lbus_do;
   input         lbus_wrn, lbus_rdn;
   input         lbus_clkn, lbus_rstn;

   // GPIO and LED
   output        gpio_startn, gpio_endn, gpio_exec;
   output [9:0]  led;

   // Clock OSC
   output        osc_en_b;
   
   // 200 MHz Kintex-7 clock
   input         clk_kintex;

   //------------------------------------------------
   // Internal clock
   wire         clk, rst;

   // Local bus
   reg [15:0]   lbus_a, lbus_di;
   
   // Block cipher
   wire [127:0] blk_kin, blk_din, blk_out;
   wire         blk_krdy, blk_kvld, blk_drdy, blk_dvld;
   wire         blk_encdec, blk_en, blk_rstn, blk_busy;
   
   wire [127:0] cpu_din, cpu_kin;
   wire         cpu_dvld, cpu_drdy, cpu_krdy;
   wire         aes_clk, aes_rst;
   
   (* S = "TRUE"*)
   wire         aes_kvld;
   (* S = "TRUE"*)
   wire         aes_en;
   
   wire         sensor_clk;
   wire         system_clk;
   wire         timer_clk;
  
   (* S = "TRUE"*)
   wire [127:0] sensor_output;
   
   (* S = "TRUE"*)
   wire [127:0] fifo_sensor_o;
   
   (* S = "TRUE"*)
   wire [127:0] fifo_aes_dout;
   
   (* S = "TRUE"*)
   wire         sensor_dvld, osc_trigger;
   
   (* S = "TRUE"*)
   wire         fifo_aes_dvld;
   
   (* S = "TRUE"*)
   wire         blk_drdy_delay_mux;
   
   (* S = "TRUE"*)
   wire         mux_ctrl;
   wire         locked, reset_n;
   wire instr_rdy;
   wire en_sensor;
   wire instr_rdy;
   wire [31:0] instr_processed;
   wire [31:0] instruction_read;
   wire [31:0] instruction_written;
   wire enb;
   wire [31:0] wishbone_data;
   
   wire locked;
   wire sensor_trg;
   wire calib_trigger;
   wire [4:0] state;
   wire exception;
   wire [11:0] address_counter;
   wire [127:0] fifo_dout;
   wire [127:0] aes_dout;
   wire sensor_reset_n;
   wire cpu_enable;
   wire fsm_dvld;
   wire dvld_mux;
   wire fifo_dvld;
   wire reset_cpu;
   wire reset_o;
   wire rst_cpu_out;
   wire reset_fifo;
   wire rst_fifo;
   
   
   //------------------------------------------------
   assign aes_en = 1'b1;
  
   //------------------------------------------------
   assign led[0] = rst;
   assign led[1] = lbus_rstn;
   assign led[2] = 1'b0;
   assign led[3] = blk_rstn;
   assign led[4] = blk_encdec;
   assign led[5] = blk_krdy;
   assign led[6] = blk_kvld;
   assign led[7] = 1'b0;
   assign led[8] = blk_dvld;
   assign led[9] = blk_busy;
   
   //------------------------------------------------
   // LBUS
   always @(posedge clk) if (lbus_wrn)  lbus_a  <= lbus_di_a;
   always @(posedge clk) if (~lbus_wrn) lbus_di <= lbus_di_a;

   (* KEEP_HIERARCHY = "TRUE" *)
   (* DONT_TOUCH = "TRUE" *)
   LBUS_IF lbus_if
     (.lbus_a(lbus_a), .lbus_di(lbus_di), .lbus_do(lbus_do),
      .lbus_wr(lbus_wrn), .lbus_rd(lbus_rdn),
      .blk_kin(blk_kin), .blk_din(blk_din), .blk_dout(blk_out),
      .blk_krdy(blk_krdy), .blk_drdy(blk_drdy), 
      .blk_kvld(blk_kvld), .blk_dvld(blk_dvld),
      .blk_encdec(blk_encdec), 
      .blk_rstn(blk_rstn), .blk_en(blk_en),
      .clk(clk), .rst(rst));

   //------------------------------------------------
   // TRIGGERS
   //assign gpio_startn = ~blk_drdy;
   assign gpio_startn = ~sensor_trg;
   assign gpio_endn   = 1'b0; //~blk_dvld;
   assign gpio_exec   = osc_trigger; //blk_busy;
   assign rst_fifo = reset_fifo & sensor_reset_n;

   //------------------------------------------------
   // ASYNC FIFOS BETWEEN LBUS CLK AND SYSTEM CLK 
      
   (* KEEP_HIERARCHY = "TRUE" *)
   fifo_wrapper fifo_key
     (.Din_i(blk_kin),
      .Dvalid_i(blk_krdy),
      .Din_ack_o(blk_kvld),
      .Dout_o(cpu_kin),
      .Dvalid_o(cpu_krdy),
      .clk_rd(system_clk),
      .clk_wr(clk),
      .rst_rd_n(reset_n),
      .rst_wr_n(blk_rstn));
      
   (* KEEP_HIERARCHY = "TRUE" *)
   fifo_wrapper fifo_plaintext
     (.Din_i(blk_din),
      .Dvalid_i(blk_drdy),
      .Din_ack_o(),
      .Dout_o(cpu_din),
      .Dvalid_o(cpu_drdy),
      .clk_rd(system_clk),
      .clk_wr(clk),
      .rst_rd_n(reset_n),
      .rst_wr_n(blk_rstn));
   
   (* KEEP_HIERARCHY = "TRUE" *)
   fifo_wrapper fifo_ciphertext
     (.Din_i(fifo_dout),
      .Dvalid_i(cpu_dvld),
      .Din_ack_o(),
      .Dout_o(blk_out),
      .Dvalid_o(blk_dvld),
      .clk_rd(clk),
      .clk_wr(system_clk),
      .rst_rd_n(blk_rstn),
      .rst_wr_n(reset_n));

   //------------------------------------------------
   // CPU AND FSM INSTANTIATION

  (* KEEP_HIERARCHY = "TRUE" *)
    CPU_Comp CPU_Comp
     (
      .input_data(cpu_kin),
      .krdy(cpu_krdy),
      .kvld(cpu_kvld), 
      
      .Din(cpu_din),
      .Drdy(cpu_drdy),
      .bsy(),
      .fsm_dvld(fsm_dvld),
      .dvld_mux(dvld_mux),
      .sensor_fifo_dvld(fifo_dvld), 

      .calib_trg(calib_trigger),
      .sensor_fifo_read(en_sensor),
      .sensor_trigger(sensor_trg),
      .osc_trigger(osc_trigger),
      .reset_fifo(reset_fifo),
      .en_cpu(cpu_enable),
      .instruction_processed(instr_processed),

      .reset_n(reset_n),
      .system_clk(system_clk),
      .timer_clk(timer_clk)
    );

   assign cpu_dvld = dvld_mux? fsm_dvld : fifo_dvld;

   //------------------------------------------------
   // SENSOR AND SENSOR FIFO INSTANTIATION
   
   (* KEEP_HIERARCHY = "TRUE" *)
   system_top 
   #(
     .COARSE_WIDTH(32),
     .FINE_WIDTH(24),
     .SENSOR_WIDTH(16))
   sensor_top
   (
     .clk_in(sensor_clk),
    
     .trigger_i(calib_trigger),
     .en_cpu(cpu_enable),
     .IDC_IDF_in(cpu_kin),
     .instruction(instr_processed),
     .dlay_line_o(sensor_output),
     .reset_n_in(sensor_reset_n)
   ); 
       
   sensor_fifo #(.N_SAMPLES(2048)) sensor_fifo
      (.sensor_i(sensor_output),
       .aes_drdy_i(sensor_trg),

       // Read side, one sample read from FIFO at a time
       .blk_drdy_i(en_sensor),
       .sensor_o(fifo_dout),
       .sensor_dvld_o(fifo_dvld),
       .mux_ctrl_o(mux_ctrl),

       .clk_wr(sensor_clk),
       .clk_rd(system_clk),
       .reset_n(rst_fifo)
       );

   //------------------------------------------------
   // CLOCK AND RESET GENERATORS
   
   MK_CLKRST mk_clkrst (.clkin(lbus_clkn), .rstnin(lbus_rstn),
                        .clk(clk), .rst(rst));
                        
    clk_wizard clock_generator
    (
     .sensor_clk(sensor_clk),
     .timer_clk(timer_clk),
     .system_clk(system_clk),
     .resetn(1'b1),
     .locked(locked),
     .clk_in1(clk_kintex));  
    assign osc_en_b = 1'b1;
   
   proc_sys_reset_0 reset_generator
     (
       .slowest_sync_clk(system_clk),
       .ext_reset_in(blk_rstn),
       .aux_reset_in(1'b1),
       .mb_debug_sys_rst(1'b0),
       .dcm_locked(locked),
       .mb_reset(),
       .bus_struct_reset(), 
       .peripheral_reset(),
       .interconnect_aresetn(),
       .peripheral_aresetn(reset_n));
       
    proc_sys_reset_1 reset_generator_2
     ( .slowest_sync_clk(sensor_clk),
       .ext_reset_in(blk_rstn),
       .aux_reset_in(1'b1),
       .mb_debug_sys_rst(1'b0),
       .dcm_locked(locked),
       .mb_reset(),
       .bus_struct_reset(), 
       .peripheral_reset(),
       .interconnect_aresetn(),
       .peripheral_aresetn(sensor_reset_n));    

endmodule // CHIP_SASEBO_GIII_AES


   
//================================================ MK_CLKRST
module MK_CLKRST (clkin, rstnin, clk, rst);
   //synthesis attribute keep_hierarchy of MK_CLKRST is no;
   
   //------------------------------------------------
   input  clkin, rstnin;
   output clk, rst;
   
   //------------------------------------------------
   wire   refclk;
//   wire   clk_dcm, locked;

   //------------------------------------------------ clock
   IBUFG u10 (.I(clkin), .O(refclk)); 

/*
   DCM_BASE u11 (.CLKIN(refclk), .CLKFB(clk), .RST(~rstnin),
                 .CLK0(clk_dcm),     .CLKDV(),
                 .CLK90(), .CLK180(), .CLK270(),
                 .CLK2X(), .CLK2X180(), .CLKFX(), .CLKFX180(),
                 .LOCKED(locked));
   BUFG  u12 (.I(clk_dcm),   .O(clk));
*/

   BUFG  u12 (.I(refclk),   .O(clk));

   //------------------------------------------------ reset
   MK_RST u20 (.locked(rstnin), .clk(clk), .rst(rst));
endmodule // MK_CLKRST



//================================================ MK_RST
module MK_RST (locked, clk, rst);
   //synthesis attribute keep_hierarchy of MK_RST is no;
   
   //------------------------------------------------
   input  locked, clk;
   output rst;

   //------------------------------------------------
   reg [15:0] cnt;
   
   //------------------------------------------------
   always @(posedge clk or negedge locked) 
     if (~locked)    cnt <= 16'h0;
     else if (~&cnt) cnt <= cnt + 16'h1;

   assign rst = ~&cnt;
endmodule // MK_RST

