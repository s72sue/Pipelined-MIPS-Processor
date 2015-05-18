/*///////////////////////////////////////////////////////////////////////////////////////////////////////////////
Register File Module

Register file has only one read/write port so reads happen before writes in the same clock cycle
Register file has outputs rsOut and rtOut (values store in the registers)
This file is instantiated in the decode module

////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

module register_file (
    clk,
	rsIn,
    rtIn,
    rdIn,
    rsOut,
    rtOut,
    reg_wren,
    writeBack_data,
    display_regs
	//access size input?
);
   
   // MIPS ISA has 32 (32 bit each) integer registers
    parameter NUM_REGISTERS = 32;				// 32 registers
	parameter REGISTER_WIDTH = 32;				// 32 bits
	parameter MEMORY_DEPTH = 1048576;			// 1 MB
    
    input wire clk;
    input wire[0:4] rdIn;						// 5 bits for the destination register
	input wire[0:4] rsIn;						// 5 bits for each of the source registers
    input wire[0:4] rtIn;
    
	input wire[0:31] writeBack_data;			// data bus: width of data element = 32 bits
    input wire display_regs; 					// flag to display the contents of registers for testing purposes

    input wire reg_wren;
	
	output reg[0:31] rsOut;
    output reg[0:31] rtOut;

	// declaration of 32 registers (32 bits each)
    reg[0:REGISTER_WIDTH-1] registers[0:NUM_REGISTERS-1];

	// Initializing the registers with the values 
	// which are the same as their respective indexes
	integer i;
    initial begin
        for (i = 0; i < NUM_REGISTERS; i = i + 1) begin
            registers[i] = i;
        end 
        registers[29] <= 32'h80020000 + MEMORY_DEPTH;					// register 29 is the stack pointer in MIPS. Assume: 32'h80022000 starting address of the stack
    end 


	// do the register reads on the positive edge of the clock
    always @(posedge clk) begin	
		rsOut <= registers[rsIn];
		rtOut <= registers[rtIn];
		//$display("CHECKING INPUTS REG FILE: rs %d, rt: %d, rd: %d", rsIn, rtIn, rdIn); 	
        $display("time: %d, REGISTER FILE: OUPUTS:  Rs_data: %d, Rt_data: %d", $time, registers[rsIn], registers[rtIn]);      
    end

	
    // Do the writes on the negative edge of the clock
	// Register r0 should always have a value 0, therefore, any writes to this register are ignored
	// In case of write requests to the other registers, writeBack_data is used 
	// to replace the original value stored in the register
	always @(negedge clk) begin
		//$display("TEST TEST TEST reg_wren = %d" , reg_wren);
		if(rdIn == 0 && reg_wren == 1) begin
			$display("============ DESTINATION FOR THE WRITE IS $ZERO ===========");
			$display("============ THIS WRITE WILL BE IGNORED ===========");
		end
		else if(rdIn != 0 && reg_wren == 1 && writeBack_data !== 32'hxxxxxxxx) begin
			$display("WB: writing: %d to register #: %d, time: %d", writeBack_data, rdIn, $time);
			registers[rdIn] = writeBack_data;
		end
    end
 
 
	// display the contents of registers if display_regs flag is turned on
    always @(posedge clk) begin
		if (display_regs) begin
            for (i = 0; i < NUM_REGISTERS; i = i + 1) begin
                $display("Register %d, value: %d", i, registers[i]);
            end
        end
    end
	

endmodule