/*///////////////////////////////////////////////////////////////////////////////////////////////////////////////
Data Memory Stage

Instantiates an instance of the main memory for storing data

////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

`include "control.vh"

module data_memory (
    clk,
    mem_address,
    mem_data_in,
	rd_in,
	control_in,
    mem_data_out,
    rd_data_out,
	rd_out,
    control_out   
);

	// inputs
    input wire 	clk; 
    input wire[0:31] mem_address;
    input wire[0:31] mem_data_in;
	input wire[0:4] rd_in;
    input wire[0:`CONTROL_BITS-1] control_in;
    
	// outputs
	output reg[0:31] mem_data_out;
    output reg[0:31] rd_data_out;
    output reg[0:4] rd_out;
    output reg[0:`CONTROL_BITS-1] control_out;
    
    wire[0:31] memory_data_out;
	wire [0:1] access_size;
	wire mem_wren;

    assign mem_wren = control_in[`MEM_WE];
	assign access_size = (control_in[`ACCESS_SIZE_b1] == 0 && control_in[`ACCESS_SIZE_b2] == 1) ? 2'b01 : 2'b11;


	//instantiating the data memory
	main_memory data_mem (
		.clk(clk),								 	
		.address(mem_address),					 	
		.data_in(mem_data_in),					
		.data_out(memory_data_out),				
		.access_size(access_size),				 
		.write_enable(mem_wren)			
	);
   
    always @(posedge clk) begin
	  rd_out <= rd_in;
	  mem_data_out = memory_data_out;
	  control_out = control_in;
	  
	  if ( control_in[`MEM_WE] == 1'b1 ) begin
		$display("IN DATAMEM STAGE, rd_in = %d  : mem_address = %d time = %d", rd_in, mem_address, $time);
		$display("IN DATAMEM STAGE, SW: mem_data_in = %d, time = %d", mem_data_in, $time);
	  end else if ( control_in[`MEM_READ] == 1'b1 ) begin
		$display("IN DATAMEM STAGE, rd_in = %d  : mem_address = %h, time = %d", rd_in, mem_address, $time);
		$display("IN DATAMEM STAGE, LW: mem_data_out = %d, time = %d", mem_data_out, $time);
	  end
	  
    end
    
	always @(posedge clk) begin
		// check whether JAL instruction
		if (control_in[`LINK] == 0) begin
			rd_data_out <= mem_address;
		end else begin
			rd_data_out <= mem_data_in;   	// rt_data coming from execute which contains pc + 8 -> will be written to R31
		end
    end
	
	// WM bypass
	always @(negedge clock) begin
		if ( WE_writeBack_stage == 1 && rd_writeBack_stage != 0 && rs == rd_writeBack_stage && rd_alu_stage == rs ) begin
			//Forward_rs = 10;
			rs_data_out = mem_stage_data_in;
		end else begin
			rs_data_out = rs_data;
		end 	
		if ( WE_writeBack_stage == 1 && rd_writeBack_stage != 0 && rt == rd_writeBack_stage  && rd_alu_stage == rt) begin
			//Forward_rt = 10;
			rt_data_out = mem_stage_data_in;
		end else begin
			rt_data_out = rt_data;
		end 
	end	      

endmodule
