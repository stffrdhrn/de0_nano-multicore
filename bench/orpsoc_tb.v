`include "timescale.v"

module orpsoc_tb
#(parameter option_pipeline = "CAPPUCCINO");

reg clk   = 0;
reg rst_n = 1;

wire uart_tx;

// 50 Mhz clock
always
	#10 clk <= ~clk;

initial begin
	#100 rst_n <= 0;
	#200 rst_n <= 1;
end

vlog_tb_utils vlog_tb_utils0();

reg enable_jtag_vpi;
initial enable_jtag_vpi = $test$plusargs("enable_jtag_vpi");

jtag_vpi jtag_vpi0
(
	.tms		(tms),
	.tck		(tck),
	.tdi		(tdi),
	.tdo		(tdo),
	.enable		(enable_jtag_vpi),
	.init_done	(orpsoc_tb.dut.wb_rst));

orpsoc_top dut
(
	.option_pipeline	(option_pipeline),
	.sys_clk_pad_i		(clk),
	.rst_n_pad_i		(rst_n),
	//JTAG interface
	.tms_pad_i		(tms),
	.tck_pad_i		(tck),
	.tdi_pad_i		(tdi),
	.tdo_pad_o		(tdo),
        //SDRAM Interface
	.sdram_ba_pad_o		(sdram_ba),
	.sdram_a_pad_o		(sdram_addr),
	.sdram_cs_n_pad_o	(sdram_cs_n),
	.sdram_ras_pad_o	(sdram_ras),
	.sdram_cas_pad_o	(sdram_cas),
	.sdram_we_pad_o		(sdram_we),
	.sdram_dq_pad_io	(sdram_dq),
	.sdram_dqm_pad_o	(sdram_dqm),
	.sdram_cke_pad_o	(sdram_cke),
	.sdram_clk_pad_o	(sdram_clk),
	//UART interface
	.uart0_srx_pad_i	(),
	.uart0_stx_pad_o	(uart_tx)
);

////////////////////////////////////////////////////////////////////////
//
// instruction monitor
//
////////////////////////////////////////////////////////////////////////
generate
	if (pipeline=="MAROCCHINO") begin : genmon
		or1k_marocchino_monitor #(.LOG_DIR(".")) i_monitor();
	end

	else begin : genmon
		mor1kx_monitor #(.LOG_DIR(".")) i_monitor();
	end
endgenerate

////////////////////////////////////////////////////////////////////////
//
// SDRAM
//
////////////////////////////////////////////////////////////////////////

	wire	[1:0]	sdram_ba;
	wire	[12:0]	sdram_addr;
	wire		sdram_cs_n;
	wire		sdram_ras;
	wire		sdram_cas;
	wire		sdram_we;
	wire	[15:0]	sdram_dq;
	wire	[1:0]	sdram_dqm;
	wire		sdram_cke;
	wire		sdram_clk;

mt48lc16m16a2_wrapper
  #(.ADDR_BITS (13), .TPROP_PCB(2.0))
sdram_wrapper0
  (.clk_i   (sdram_clk),
   .rst_n_i (rst_n),
   .dq_io   (sdram_dq),
   .addr_i  (sdram_addr),
   .ba_i    (sdram_ba),
   .cas_i   (sdram_cas),
   .cke_i   (sdram_cke),
   .cs_n_i  (sdram_cs_n),
   .dqm_i   (sdram_dqm),
   .ras_i   (sdram_ras),
   .we_i    (sdram_we));

// baud of 115200, 1/115200 = 8680 ns
uart_decoder
	#(.uart_baudrate_period_ns(8680))
uart_decoder0
(
	.clk(clk),
	.uart_tx(uart_tx)
);

endmodule
