/*////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Parser Module

Used to parse the SREC files

state = 1 => WRITE: parser is writing to the memory
state = 0 => READ: parser is done writing, so reads can 
			 be performed now.

////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/



module parser(
clk,
mem_address,
mem_data,
state_variable
);

	
	parameter fSREC = "SREC file to be Parsed";

	// inputs for driving the memory	
	input clk;	
	output reg [0:31] mem_address;
	output reg [0:31] mem_data;
	output reg state_variable;

	reg [3:0] tmp_address [0:7];
	reg [3:0] tmp_data 	[0:7];        
	
	integer fd;
	integer byte_count;
	integer c = 0;
	integer index = 0;
	integer data = 0;
	integer addr = 0;
	
	// variables needed for displaying relevant data
	integer test;
	integer test2;
	integer test3;
	integer test4;
	integer test5;
	integer test6;

			
	

//-----------------------Parsing Starts----------------------
	initial begin
		
		$display();	
		$display("///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////");	
		$display("///////////////////////////////////////////////////BEGINNING OF WRITES TO THE MAIN MEMORY/////////////////////////////////////////////////////////////////");
		$display("///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////");
		$display();	
		//Open SREC file
		fd = $fopen(fSREC, "r");
		
		//Read the SREC file char by char 
		c = 1;
		while (c != 32'hFFFF_FFFF) begin
			state_variable = 0; //state is in parsing
			
			c = $fgetc(fd);		
			$display ( "c = %c", c);
			
			/* - Check if the header char is 'S'
			   - Acknowledge that it is a new line if 'S' is found
			*/   	
			if (c == 83) begin
				c = $fgetc(fd);
				$display ( "c = %c", c);
				//-----------------------------Case : S0-------------------------------
				if (c == 48) begin
				
					//Parse Byte Count
					byte_count = atoi($fgetc(fd)) * 16;
					byte_count = byte_count + atoi($fgetc(fd));
					$display ( "byte_count =%d", byte_count);
					
					//Parse Address
					while(index < 8) begin
						test = atohex($fgetc(fd));
						$display("address = %h", test);
						
						tmp_address[addr] = test;
						addr = addr + 1;
						index = index + 1;
					end
					
					//Parse Data
					while(index < ((byte_count*2)-2)) begin
						test2 = atohex($fgetc(fd));
						$display("data = %h", test2);
						
						tmp_data[data] = test2;
						data = data + 1;
						index = index + 1;
						
					end
					
					//Reset Buffer index
					addr = 0;
					data = 0;
					index = 0;
					
					//Display parsed S0 message
					//$display("S0 : address = %h, data = %h", tmp_address, tmp_data);
					
				//-----------------------------Case : S3-------------------------------
				end else if(c == 51) begin
					
					//Parse Byte Count
					byte_count = atoi($fgetc(fd)) * 16;
					byte_count = byte_count + atoi($fgetc(fd));
					
					//Parse Address
					while(index < 8) begin
						test3 = atohex($fgetc(fd));
						$display("address = %h", test3);
						tmp_address[addr] = test3;
						addr = addr + 1;
						index = index + 1;
					end
					
	
					//Parse Data
					while(index < ((byte_count*2)-2)) begin
						while(data < 8) begin
							test4 = atohex($fgetc(fd));
							$display("data = %h", test4);
						
							tmp_data[data] = test4;
							data = data + 1;
							index = index + 1;
						end
						
						
						@ (posedge clk) begin
							mem_data = {tmp_data[0], tmp_data[1], tmp_data[2], tmp_data[3], tmp_data[4], tmp_data[5], tmp_data[6], tmp_data[7]};
							mem_address = {tmp_address[0], tmp_address[1], tmp_address[2], tmp_address[3], tmp_address[4], tmp_address[5], tmp_address[6], tmp_address[7]};
						end
						
						@ (posedge clk) begin
							data = 0;
							tmp_address[7] = tmp_address[7] + 4'h4;
						end	
						
					end
					
					//Reset Buffer index
					addr = 0;
					data = 0;
					index = 0;
					
					//Output Parsed Data
					 
					
				//-----------------------------Case : S7-------------------------------
				end else if(c == 55) begin	
					
					//Parse Byte Count
					byte_count = atoi($fgetc(fd)) * 16;
					byte_count = byte_count + atoi($fgetc(fd));
					
					//Parse Address
					while(index < 8) begin
						test5 = atohex($fgetc(fd));
						$display("address = %h", test5);
						tmp_address[addr] = test5;
						addr = addr + 1;
						index = index + 1;
					end
					
					//Parse Data
					while(index < ((byte_count*2)-2)) begin
						test6 = atohex($fgetc(fd));
						$display("data = %h", test6);
						tmp_data[data] = test6;
						data = data + 1;
						index = index + 1;
					end
					
					//Reset Buffer index
					addr = 0;
					data = 0;
					index = 0;
					
					//Display parsed S7message
					//$display("S7 : address = %h, data = %h", tmp_address, tmp_data);
				end
			end
		end
		
		@ (posedge clk);
		state_variable = 1; //parsing is done
		//$display ( "state = %b", state_variable);
		
	end			
//--------------------------------------Functions---------------------------------------
function integer atoi;

	input integer char;

	begin          
		if(char > 57) begin
    		char = char - 55;
    	end else begin
    		char = char - 48;
    	end
    	       
    	atoi = char;
	end
endfunction
//--------------------------------------------------------------------------------------    
function [3:0] atohex;
	
	input integer char2;
      
    begin        
    	if(char2 > 57) begin
        	char2 = char2 - 23;
        end else begin
        	char2 = char2 - 16;
        end
                 
        atohex = char2;
    end
endfunction
//--------------------------------------------------------------------------------------
endmodule