/*////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Main Memory Module

write_enable = 1 => WRITE
write_enable = 0 => READ

Big Endian
Reads and Writes supported

////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/


module main_memory (
clk				, 	// this is the clock input port  
address			, 	// address input port( address of a memory location )
data_in			,	// port used to receive data 
data_out		, 	// port through which memory sends a response
access_size		, 	// amount of data to respond ( valid sizes: 1,2,4 bytes ) 
write_enable		// port to specify whether the memory is read from or written to
);

////////////////////////////////////*** DECLARATIONS AND INITILIZATIONS ***/////////////////////////////////////////

	//Parameter declaration
	parameter OFFSET = 32'h80020000;
	parameter MEMORY_WIDTH = 8;				// 8 bits 
	parameter MEMORY_DEPTH = 1048576;		// configurable depth of the main memory
											// 1 MB of memory, considering that 1MB = 1024KB = 1024*1024 
											// Any number based on memory is always 2 to the power of number

	//Input declaration
	input wire clk;		
	input wire [0:31] address;		
	input wire [0:31] data_in;		
	input wire [0:1] access_size;		
	input wire write_enable;		
		
	//Output declaration
	output reg [0:31] data_out;	

	// the main memory -> RAM
	reg [0:MEMORY_WIDTH-1] memory [OFFSET:OFFSET+MEMORY_DEPTH-1];		

	
	// internal registers for registering inputs
	reg [0:31] reg_data_in; 
	reg [0:31] reg_data_out;
	reg [0:31] reg_address;
	
	
	// Initializing the memory
	integer i;
	initial begin
		for ( i=0; i < MEMORY_DEPTH; i = i+1) begin
			memory[i] = 0;
		end
	end


	
////////////////////////////////////*** RISING EDGE OF THE CLOCK ***////////////////////////////////////////////	
	

	// at the rising edge if the read is enabled, register the data
	// if write is enabled, read the data from the memory and store it in a register
	always @ (posedge clk) begin
		#3
		if (address >= OFFSET && address <= (OFFSET+MEMORY_DEPTH-1)) begin
			if (write_enable == 1'b1) begin
				reg_data_in [0:31] <= data_in [0:31];
				reg_address [0:31] <= address [0:31];	
			end	else if (write_enable == 1'b0) begin
				// Access Size: 01 -> 1 byte , 10 -> 2 bytes, 11 -> 4 bytes	
				case (access_size) 
				2'b11:	begin
						reg_data_out [0:31] <= {memory[address], memory[address+1], memory[address+2], memory[address+3]};
						end
				2'b10:	begin
						reg_data_out [0:15] <= 0;
						reg_data_out [16:31] <= {memory[address], memory[address+1]};
						end
				2'b01:	begin
						reg_data_out [0:23] <= 0;
						reg_data_out [24:31] <= memory[address];
						end
				endcase
				reg_address [0:31] <= address [0:31];	
			end
		end else begin
			//$display ("ERROR: Memory address out of bound");
		end	
	end	

	
	
////////////////////////////////////*** FALLING EDGE OF THE CLOCK ***////////////////////////////////////////////	


	// At the falling edge of the clk, if its a read put the 
	// data in the reg_data_in register on the data_out lines
	// If its a write, write the data in the reg_data_out register to the data_out lines 
	always @ (negedge clk) begin
		#3
		if (address >= OFFSET && address <= (OFFSET+MEMORY_DEPTH-1)) begin
			if (write_enable == 1'b1) begin
				case (access_size) 
					2'b11:	begin
							memory [reg_address] <= reg_data_in[0:7];
							memory [reg_address+1] <= reg_data_in[8:15];
							memory [reg_address+2] <= reg_data_in[16:23];
							memory [reg_address+3] <= reg_data_in[24:31];
							end
					2'b10:	begin
							memory [reg_address] <= reg_data_in[16:23];
							memory [reg_address+1] <= reg_data_in[24:31];
							end
					2'b01:	begin
							memory [reg_address] <= reg_data_in[24:31];
							end
				endcase
			end
			if (write_enable == 1'b0) begin
				data_out [0:31] <= reg_data_out [0:31];
			end
		end else begin
			//$display ("ERROR: Memory address out of bound");
		end	
	end
		
endmodule		


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

