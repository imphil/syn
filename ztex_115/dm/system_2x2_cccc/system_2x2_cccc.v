/* Copyright (c) 2012-2014 by the author(s)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * =============================================================================
 *
 * Top-level module for a 2x2 CCCC distributed memory system running on a
 * ZTEX USB-FPGA 1.15 board
 *
 * Hardware target: ZTEX 1.15b/d USB-FPGA Boards
 * System: system_2x2_cccc_dm
 *
 * Author(s):
 *   Stefan Wallentowitz <stefan.wallentowitz@tum.de>
 *   Michael Tempelmeier <michael.tempelmeier@tum.de>
 *   Hans-Christian Wild <hans-christian.wild@mytum.de>
 *   Philipp Wagner <philipp.wagner@tum.de>
 */

`include "lisnoc16_def.vh"
`include "optimsoc_def.vh"
`include "dbg_config.vh"

module system_2x2_cccc(
`ifdef OPTIMSOC_CTRAM_WIRES
   mcb3_dram_a, mcb3_dram_ba, mcb3_dram_ras_n, mcb3_dram_cas_n,
   mcb3_dram_we_n, mcb3_dram_cke, mcb3_dram_dm, mcb3_dram_udm,
   mcb3_dram_ck, mcb3_dram_ck_n, mcb3_dram_dq, mcb3_dram_udqs,
   mcb3_dram_udqs_n, mcb3_rzq, mcb3_zio, mcb3_dram_dqs,
   mcb3_dram_dqs_n,
`endif

   /*AUTOARG*/
   // Outputs
   fx2_sloe_n, fx2_slrd_n, fx2_slwr_n, fx2_pktend_n, fx2_fifoadr,
   // Inouts
   fx2_fd,
   // Inputs
   clk, fx2_ifclk, fx2_com_rst, fx2_logic_rst, fx2_flaga_n,
   fx2_flagb_n, fx2_flagc_n, fx2_flagd_n
   );

   // 32 MByte for each of the four compute tiles (128 MByte total)
   // The ZTEX 1.15 boards provide 128 MByte DDR2 memory, which is
   // used by the compute tile memories.
   localparam MEM_SIZE = 32*1024*1024;
   // Memory file, used only in simulation
   parameter MEM_FILE = "ct.vmem";

   // NoC configuration
   localparam NOC_FLIT_DATA_WIDTH = 32;
   localparam NOC_FLIT_TYPE_WIDTH = 2;
   localparam NOC_FLIT_WIDTH = NOC_FLIT_DATA_WIDTH + NOC_FLIT_TYPE_WIDTH;
   localparam NOC_VCHANNELS = `VCHANNELS;

   // Debug NoC configuration
   localparam DBG_NOC_DATA_WIDTH = `FLIT16_CONTENT_WIDTH;
   localparam DBG_NOC_FLIT_TYPE_WIDTH = `FLIT16_TYPE_WIDTH;
   localparam DBG_NOC_FLIT_WIDTH = DBG_NOC_DATA_WIDTH + DBG_NOC_FLIT_TYPE_WIDTH;
   localparam DBG_NOC_VCHANNELS = 2;
   localparam DBG_NOC_CONF_VCHANNEL = 0;
   localparam DBG_NOC_TRACE_VCHANNEL = 1;

   // Clock
   input clk;

   // FX2 USB interface
   input        fx2_ifclk;
   input        fx2_com_rst;
   input        fx2_logic_rst;
   inout [15:0] fx2_fd;
   output       fx2_sloe_n;
   output       fx2_slrd_n;
   output       fx2_slwr_n;
   output       fx2_pktend_n;
   output [1:0] fx2_fifoadr;
   input        fx2_flaga_n;
   input        fx2_flagb_n;
   input        fx2_flagc_n;
   input        fx2_flagd_n;

   // MCB connection
`ifdef OPTIMSOC_CTRAM_WIRES
   inout [15:0]  mcb3_dram_dq;
   output [12:0] mcb3_dram_a;
   output [2:0]  mcb3_dram_ba;
   output        mcb3_dram_ras_n;
   output        mcb3_dram_cas_n;
   output        mcb3_dram_we_n;
   output        mcb3_dram_cke;
   output        mcb3_dram_dm;
   inout         mcb3_dram_udqs;
   inout         mcb3_dram_udqs_n;
   inout         mcb3_rzq;
   inout         mcb3_zio;
   output        mcb3_dram_udm;
   inout         mcb3_dram_dqs;
   inout         mcb3_dram_dqs_n;
   output        mcb3_dram_ck;
   output        mcb3_dram_ck_n;

   // clocks
   wire clk_ddr2;
`endif

   // system control signals
   wire sys_clk_disable;
   wire sys_clk_is_halted;

   // system control
   wire cpu_reset;
   wire cpu_stall;
   wire start_cpu;

   // connection to the USB interface
   wire [DBG_NOC_FLIT_WIDTH-1:0] dbgnoc_in_flit;
   wire [DBG_NOC_VCHANNELS-1:0] dbgnoc_in_valid;
   wire [DBG_NOC_VCHANNELS-1:0] dbgnoc_in_ready;
   wire [DBG_NOC_FLIT_WIDTH-1:0] dbgnoc_out_flit;
   wire [DBG_NOC_VCHANNELS-1:0] dbgnoc_out_valid;
   wire [DBG_NOC_VCHANNELS-1:0] dbgnoc_out_ready;

   wire clk_sys;
   wire clk_dbg;
   wire rst_sys;
   wire rst_cpu;

   wire glip_ctrl_logic_rst;

   clockmanager_ztex115
`ifdef OPTIMSOC_CTRAM_WIRES
     #(.ENABLE_DDR_CLOCK(1))
`endif
      u_clockmanager(.clk     (clk),
                     .rst     (glip_ctrl_logic_rst),
                     .clk_ct  (clk_sys),
                     .clk_dbg (clk_dbg),
                     .clk_noc (),
`ifdef OPTIMSOC_CTRAM_WIRES
                     .clk_ddr (clk_ddr2),
`else
                     .clk_ddr (),
`endif
                     .rst_sys  (rst_sys),
                     .rst_cpu  (rst_cpu),
                     .cpu_reset (cpu_reset),
                     .cpu_start (start_cpu),
                     .sys_halt (sys_clk_disable),
                     .sys_is_halted (sys_clk_is_halted));

   wire [`DEBUG_TRACE_EXEC_WIDTH*4-1:0] trace;


`ifdef OPTIMSOC_DEBUG_ENABLE_MAM
   wire [4*32-1:0] wb_mam_adr_o;
   wire [4*1-1:0]  wb_mam_cyc_o;
   wire [4*32-1:0] wb_mam_dat_o;
   wire [4*4-1:0]  wb_mam_sel_o;
   wire [4*1-1:0]  wb_mam_stb_o;
   wire [4*1-1:0]  wb_mam_we_o;
   wire [4*1-1:0]  wb_mam_cab_o;
   wire [4*3-1:0]  wb_mam_cti_o;
   wire [4*2-1:0]  wb_mam_bte_o;
   wire [4*1-1:0]  wb_mam_ack_i;
   wire [4*1-1:0]  wb_mam_rty_i;
   wire [4*1-1:0]  wb_mam_err_i;
   wire [4*32-1:0] wb_mam_dat_i;
`endif

`ifdef OPTIMSOC_CTRAM_WIRES
   wire            ddr2_calib_done;

   wire [4*32-1:0] wb_mem_adr_i;
   wire [4*1-1:0]  wb_mem_cyc_i;
   wire [4*32-1:0] wb_mem_dat_i;
   wire [4*4-1:0]  wb_mem_sel_i;
   wire [4*1-1:0]  wb_mem_stb_i;
   wire [4*1-1:0]  wb_mem_we_i;
   wire [4*1-1:0]  wb_mem_cab_i;
   wire [4*3-1:0]  wb_mem_cti_i;
   wire [4*2-1:0]  wb_mem_bte_i;
   wire [4*1-1:0]  wb_mem_ack_o;
   wire [4*1-1:0]  wb_mem_rty_o;
   wire [4*1-1:0]  wb_mem_err_o;
   wire [4*32-1:0] wb_mem_dat_o;
`endif

   wire [`DEBUG_TRACE_EXEC_WIDTH*4-1:0] trace;

   /* system_2x2_cccc_dm AUTO_TEMPLATE(
    .clk (clk_sys),
    .rst_sys (rst_sys),
    .rst_cpu (rst_cpu),
    ); */
   system_2x2_cccc_dm
      #(.MEM_SIZE(MEM_SIZE),
        .MEM_FILE(MEM_FILE))
      u_system(
               .trace                      (trace),
`ifdef OPTIMSOC_DEBUG_ENABLE_MAM
               .wb_mam_ack_i               (wb_mam_ack_i),
               .wb_mam_rty_i               (wb_mam_rty_i),
               .wb_mam_err_i               (wb_mam_err_i),
               .wb_mam_dat_i               (wb_mam_dat_i),
               .wb_mam_adr_o               (wb_mam_adr_o),
               .wb_mam_cyc_o               (wb_mam_cyc_o),
               .wb_mam_dat_o               (wb_mam_dat_o),
               .wb_mam_sel_o               (wb_mam_sel_o),
               .wb_mam_stb_o               (wb_mam_stb_o),
               .wb_mam_we_o                (wb_mam_we_o),
               .wb_mam_cab_o               (wb_mam_cab_o),
               .wb_mam_cti_o               (wb_mam_cti_o),
               .wb_mam_bte_o               (wb_mam_bte_o),
`endif
`ifdef OPTIMSOC_CTRAM_WIRES
               .wb_mem_ack_o               (wb_mem_ack_o),
               .wb_mem_rty_o               (wb_mem_rty_o),
               .wb_mem_err_o               (wb_mem_err_o),
               .wb_mem_dat_o               (wb_mem_dat_o),
               .wb_mem_adr_i               (wb_mem_adr_i),
               .wb_mem_cyc_i               (wb_mem_cyc_i),
               .wb_mem_dat_i               (wb_mem_dat_i),
               .wb_mem_sel_i               (wb_mem_sel_i),
               .wb_mem_stb_i               (wb_mem_stb_i),
               .wb_mem_we_i                (wb_mem_we_i),
               .wb_mem_cab_i               (wb_mem_cab_i),
               .wb_mem_cti_i               (wb_mem_cti_i),
               .wb_mem_bte_i               (wb_mem_bte_i),
`endif
               /*AUTOINST*/
               // Inputs
               .clk                     (clk_sys),               // Templated
               .rst_sys                 (rst_sys),               // Templated
               .rst_cpu                 (rst_cpu));               // Templated

   // Cypress FX2 USB interface using GLIP
   wire        glip_fifo_out_valid;
   wire        glip_fifo_out_ready;
   wire [15:0] glip_fifo_out_data;
   wire        glip_fifo_in_valid;
   wire        glip_fifo_in_ready;
   wire [15:0] glip_fifo_in_data;

   wire glip_com_rst;

   glip_cypressfx2_toplevel
      u_glip(// Clock and reset
             .clk                       (clk_dbg),

             // XXX: Feeding rst_sys to the rst input of GLIP is a workaround
             // In order to support hot-attach, GLIP has separate communication
             // and logic reset signals. But resetting the communication also
             // requires the Debug NoC -> FIFO communication to be reset to a
             // well-known starting point (i.e. the beginning of a NoC packet).
             // This is currently not implemented. If the communication starts
             // in the middle of a packet, there is no way for the receiver to
             // synchronize to the data stream. As a workaround, we simply
             // reset the whole system when connecting, thus no hot-attach
             // capability, and make sure we also reset the communication
             // interface when the system is reset.
             .rst                       (rst_sys),

             .com_rst                   (glip_com_rst),

             // FX2 Interface
             .fx2_sloe_n                (fx2_sloe_n),
             .fx2_slrd_n                (fx2_slrd_n),
             .fx2_slwr_n                (fx2_slwr_n),
             .fx2_pktend_n              (fx2_pktend_n),
             .fx2_fifoadr               (fx2_fifoadr[1:0]),
             .fx2_ifclk                 (fx2_ifclk),
             .fx2_com_rst               (fx2_com_rst),
             .fx2_logic_rst             (fx2_logic_rst),
             .fx2_flaga_n               (fx2_flaga_n),
             .fx2_flagb_n               (fx2_flagb_n),
             .fx2_flagc_n               (fx2_flagc_n),
             .fx2_flagd_n               (fx2_flagd_n),
             .fx2_fd                    (fx2_fd[15:0]),

             // FIFO Interface
             .fifo_out_ready            (glip_fifo_out_ready),
             .fifo_in_valid             (glip_fifo_in_valid),
             .fifo_in_data              (glip_fifo_in_data),
             .fifo_out_valid            (glip_fifo_out_valid),
             .fifo_out_data             (glip_fifo_out_data),
             .fifo_in_ready             (glip_fifo_in_ready),

             // Control interface
             .ctrl_logic_rst            (glip_ctrl_logic_rst));

   fifo_dbg_if
      #(.DBG_NOC_VCHANNELS(DBG_NOC_VCHANNELS),
        .DBG_NOC_USB_VCHANNEL(DBG_NOC_CONF_VCHANNEL))
      u_fifo_dbg_if(.clk(clk_dbg),
                    // This module is a "high level protocol" for GLIP, use the
                    // provided communication reset signal from GLIP; see also
                    // the comment on u_glip.rst above.
                    .rst(glip_com_rst),

                    // FIFO Interface
                    .fifo_out_valid     (glip_fifo_out_valid),
                    .fifo_out_data      (glip_fifo_out_data),
                    .fifo_in_ready      (glip_fifo_in_ready),
                    .fifo_out_ready     (glip_fifo_out_ready),
                    .fifo_in_valid      (glip_fifo_in_valid),
                    .fifo_in_data       (glip_fifo_in_data),

                    // Debug NoC interface
                    .dbgnoc_out_ready(dbgnoc_in_ready),
                    .dbgnoc_out_flit(dbgnoc_in_flit),
                    .dbgnoc_out_valid(dbgnoc_in_valid),
                    .dbgnoc_in_ready(dbgnoc_out_ready),
                    .dbgnoc_in_flit(dbgnoc_out_flit),
                    .dbgnoc_in_valid(dbgnoc_out_valid));

   // debug system
   debug_system
     #(
`ifdef OPTIMSOC_DEBUG_ENABLE_ITM
       .DEBUG_ITM_CORE_COUNT            (4),
`endif
`ifdef OPTIMSOC_DEBUG_ENABLE_STM
       .DEBUG_STM_CORE_COUNT            (4),
`endif
`ifdef OPTIMSOC_DEBUG_ENABLE_NRM
       .DEBUG_ROUTER_COUNT              (4),
       .DEBUG_ROUTER_LINKS_PER_ROUTER   (1),
`endif
`ifdef OPTIMSOC_DEBUG_ENABLE_NCM
       .OPTIMSOC_DEBUG_NCM_ID           (1),
`endif
`ifdef OPTIMSOC_DEBUG_ENABLE_MAM
       .DEBUG_MAM_MEMORY_COUNT          (4),
`endif
       .NOC_VCHANNELS                   (`VCHANNELS),
       .NOC_USED_VCHANNEL               (`VCHANNEL_LSU_REQ),
       .DBG_NOC_VCHANNELS               (DBG_NOC_VCHANNELS),
       .DBG_NOC_TRACE_VCHANNEL          (DBG_NOC_TRACE_VCHANNEL),
       .DBG_NOC_CONF_VCHANNEL           (DBG_NOC_CONF_VCHANNEL),
       .SYSTEM_IDENTIFIER (16'hce75)) // FIXME: Change system identifier
      u_dbg_system(.clk                 (clk_dbg),
                   .rst                 (rst_sys),

                   // System control
                   .sys_clk_disable     (sys_clk_disable),
                   .cpu_reset           (cpu_reset),
                   .cpu_stall           (cpu_stall),
                   .start_cpu           (start_cpu),
                   .sys_clk_is_halted   (sys_clk_is_halted),

                   .trace_ports_flat    (trace),

`ifdef OPTIMSOC_DEBUG_ENABLE_MAM
                   .wb_mam_ack_i        (wb_mam_ack_i),
                   .wb_mam_rty_i        (wb_mam_rty_i),
                   .wb_mam_err_i        (wb_mam_err_i),
                   .wb_mam_dat_i        (wb_mam_dat_i),
                   .wb_mam_adr_o        (wb_mam_adr_o),
                   .wb_mam_cyc_o        (wb_mam_cyc_o),
                   .wb_mam_dat_o        (wb_mam_dat_o),
                   .wb_mam_sel_o        (wb_mam_sel_o),
                   .wb_mam_stb_o        (wb_mam_stb_o),
                   .wb_mam_we_o         (wb_mam_we_o),
                   .wb_mam_cab_o        (wb_mam_cab_o),
                   .wb_mam_cti_o        (wb_mam_cti_o),
                   .wb_mam_bte_o        (wb_mam_bte_o),
`endif
                   // Debug NoC link to USB
                   .dbgnoc_in_flit      (dbgnoc_in_flit),
                   .dbgnoc_in_valid     (dbgnoc_in_valid),
                   .dbgnoc_in_ready     (dbgnoc_in_ready),
                   .dbgnoc_out_flit     (dbgnoc_out_flit),
                   .dbgnoc_out_valid    (dbgnoc_out_valid),
                   .dbgnoc_out_ready    (dbgnoc_out_ready));

`ifdef OPTIMSOC_CTRAM_WIRES


   /* ztex_ddr2_if AUTO_TEMPLATE(
    .ddr2_clk(clk_ddr2),
    .ddr2_rst(rst_sys),
    .wbm._clk_i (clk_sys),
    .wbm._rst_i (rst_sys),
    .wbm0_adr_i ({7'h0,wb_mem_adr_i[24:0]}),
    .wbm1_adr_i ({7'h1,wb_mem_adr_i[56:32]}),
    .wbm2_adr_i ({7'h2,wb_mem_adr_i[88:64]}),
    .wbm3_adr_i ({7'h3,wb_mem_adr_i[120:96]}),
    .wbm\(.*\)_dat_\(.*\) (wb_mem_dat_\2[(\1+1)*32-1:\1*32]),
    .wbm\(.*\)_sel_i (wb_mem_sel_i[(\1+1)*4-1:\1*4]),
    .wbm\(.*\)_cti_i (wb_mem_cti_i[(\1+1)*3-1:\1*3]),
    .wbm\(.*\)_bte_i (wb_mem_bte_i[(\1+1)*2-1:\1*2]),
    .wbm\(.*\)_\(.*\)_o (wb_mem_\2_o[\1]),
    .wbm\(.*\)_\(.*\)_i (wb_mem_\2_i[\1]),
    ); */

   ztex_ddr2_if
     #(.USE_WBPORT0(1),
       .USE_WBPORT1(1),
       .USE_WBPORT2(1),
       .USE_WBPORT3(1))
     u_ddr(/*AUTOINST*/
           // Outputs
           .ddr2_calib_done             (ddr2_calib_done),
           .mcb3_dram_a                 (mcb3_dram_a[12:0]),
           .mcb3_dram_ba                (mcb3_dram_ba[2:0]),
           .mcb3_dram_ras_n             (mcb3_dram_ras_n),
           .mcb3_dram_cas_n             (mcb3_dram_cas_n),
           .mcb3_dram_we_n              (mcb3_dram_we_n),
           .mcb3_dram_cke               (mcb3_dram_cke),
           .mcb3_dram_dm                (mcb3_dram_dm),
           .mcb3_dram_udm               (mcb3_dram_udm),
           .mcb3_dram_ck                (mcb3_dram_ck),
           .mcb3_dram_ck_n              (mcb3_dram_ck_n),
           .wbm0_ack_o                  (wb_mem_ack_o[0]),       // Templated
           .wbm0_err_o                  (wb_mem_err_o[0]),       // Templated
           .wbm0_rty_o                  (wb_mem_rty_o[0]),       // Templated
           .wbm0_dat_o                  (wb_mem_dat_o[(0+1)*32-1:0*32]), // Templated
           .wbm1_ack_o                  (wb_mem_ack_o[1]),       // Templated
           .wbm1_err_o                  (wb_mem_err_o[1]),       // Templated
           .wbm1_rty_o                  (wb_mem_rty_o[1]),       // Templated
           .wbm1_dat_o                  (wb_mem_dat_o[(1+1)*32-1:1*32]), // Templated
           .wbm2_ack_o                  (wb_mem_ack_o[2]),       // Templated
           .wbm2_err_o                  (wb_mem_err_o[2]),       // Templated
           .wbm2_rty_o                  (wb_mem_rty_o[2]),       // Templated
           .wbm2_dat_o                  (wb_mem_dat_o[(2+1)*32-1:2*32]), // Templated
           .wbm3_ack_o                  (wb_mem_ack_o[3]),       // Templated
           .wbm3_err_o                  (wb_mem_err_o[3]),       // Templated
           .wbm3_rty_o                  (wb_mem_rty_o[3]),       // Templated
           .wbm3_dat_o                  (wb_mem_dat_o[(3+1)*32-1:3*32]), // Templated
           // Inouts
           .mcb3_dram_dq                (mcb3_dram_dq[15:0]),
           .mcb3_dram_udqs              (mcb3_dram_udqs),
           .mcb3_dram_udqs_n            (mcb3_dram_udqs_n),
           .mcb3_rzq                    (mcb3_rzq),
           .mcb3_zio                    (mcb3_zio),
           .mcb3_dram_dqs               (mcb3_dram_dqs),
           .mcb3_dram_dqs_n             (mcb3_dram_dqs_n),
           // Inputs
           .ddr2_clk                    (clk_ddr2),              // Templated
           .ddr2_rst                    (rst_sys),               // Templated
           .wbm0_clk_i                  (clk_sys),               // Templated
           .wbm0_rst_i                  (rst_sys),               // Templated
           .wbm0_dat_i                  (wb_mem_dat_i[(0+1)*32-1:0*32]), // Templated
           .wbm0_adr_i                  ({7'h0,wb_mem_adr_i[24:0]}), // Templated
           .wbm0_bte_i                  (wb_mem_bte_i[(0+1)*2-1:0*2]), // Templated
           .wbm0_cti_i                  (wb_mem_cti_i[(0+1)*3-1:0*3]), // Templated
           .wbm0_cyc_i                  (wb_mem_cyc_i[0]),       // Templated
           .wbm0_sel_i                  (wb_mem_sel_i[(0+1)*4-1:0*4]), // Templated
           .wbm0_stb_i                  (wb_mem_stb_i[0]),       // Templated
           .wbm0_we_i                   (wb_mem_we_i[0]),        // Templated
           .wbm1_clk_i                  (clk_sys),               // Templated
           .wbm1_rst_i                  (rst_sys),               // Templated
           .wbm1_dat_i                  (wb_mem_dat_i[(1+1)*32-1:1*32]), // Templated
           .wbm1_adr_i                  ({7'h1,wb_mem_adr_i[56:32]}), // Templated
           .wbm1_bte_i                  (wb_mem_bte_i[(1+1)*2-1:1*2]), // Templated
           .wbm1_cti_i                  (wb_mem_cti_i[(1+1)*3-1:1*3]), // Templated
           .wbm1_cyc_i                  (wb_mem_cyc_i[1]),       // Templated
           .wbm1_sel_i                  (wb_mem_sel_i[(1+1)*4-1:1*4]), // Templated
           .wbm1_stb_i                  (wb_mem_stb_i[1]),       // Templated
           .wbm1_we_i                   (wb_mem_we_i[1]),        // Templated
           .wbm2_clk_i                  (clk_sys),               // Templated
           .wbm2_rst_i                  (rst_sys),               // Templated
           .wbm2_dat_i                  (wb_mem_dat_i[(2+1)*32-1:2*32]), // Templated
           .wbm2_adr_i                  ({7'h2,wb_mem_adr_i[88:64]}), // Templated
           .wbm2_bte_i                  (wb_mem_bte_i[(2+1)*2-1:2*2]), // Templated
           .wbm2_cti_i                  (wb_mem_cti_i[(2+1)*3-1:2*3]), // Templated
           .wbm2_cyc_i                  (wb_mem_cyc_i[2]),       // Templated
           .wbm2_sel_i                  (wb_mem_sel_i[(2+1)*4-1:2*4]), // Templated
           .wbm2_stb_i                  (wb_mem_stb_i[2]),       // Templated
           .wbm2_we_i                   (wb_mem_we_i[2]),        // Templated
           .wbm3_dat_i                  (wb_mem_dat_i[(3+1)*32-1:3*32]), // Templated
           .wbm3_adr_i                  ({7'h3,wb_mem_adr_i[120:96]}), // Templated
           .wbm3_bte_i                  (wb_mem_bte_i[(3+1)*2-1:3*2]), // Templated
           .wbm3_cti_i                  (wb_mem_cti_i[(3+1)*3-1:3*3]), // Templated
           .wbm3_cyc_i                  (wb_mem_cyc_i[3]),       // Templated
           .wbm3_sel_i                  (wb_mem_sel_i[(3+1)*4-1:3*4]), // Templated
           .wbm3_stb_i                  (wb_mem_stb_i[3]),       // Templated
           .wbm3_we_i                   (wb_mem_we_i[3]),        // Templated
           .wbm3_clk_i                  (clk_sys),               // Templated
           .wbm3_rst_i                  (rst_sys));               // Templated
`endif

   `include "optimsoc_functions.vh"
endmodule

// Local Variables:
// verilog-library-directories:("../../../src/rtl/*/verilog/" "../../../" "." )
// verilog-auto-inst-param-value: t
// End:
