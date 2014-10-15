/**
 * synthesizable spi peripheral
 * Joshua Vasquez
 * September 26 - October 8, 2014
 */

module spiSendReceive( input logic cs, sck, mosi, setNewData,
            input logic [7:0] dataToSend, 
            output logic miso,
            output logic [7:0] dataReceived);

    logic [7:0] shiftReg;
    logic validClk;
  
    assign validClk = cs ? 1'b0   :
                           sck;
    
    always_ff @ (negedge validClk, posedge setNewData)
    begin
        if (setNewData)
        begin
            shiftReg[7] <= dataToSend[0];
            shiftReg[6] <= dataToSend[1];
            shiftReg[5] <= dataToSend[2];
            shiftReg[4] <= dataToSend[3];
            shiftReg[3] <= dataToSend[4];
            shiftReg[2] <= dataToSend[5];
            shiftReg[1] <= dataToSend[6];
            shiftReg[0] <= dataToSend[7];
        end
        else
        begin
        // Handle Output.
            shiftReg[7:0] <= (shiftReg[7:0] >> 1);
        end
    end
    
    always_ff @ (posedge validClk)
    begin
        // Handle Input.
            dataReceived[0] <= mosi;
            dataReceived[1] <= dataReceived[0];
            dataReceived[2] <= dataReceived[1];
            dataReceived[3] <= dataReceived[2];
            dataReceived[4] <= dataReceived[3];
            dataReceived[5] <= dataReceived[4];
            dataReceived[6] <= dataReceived[5];
            dataReceived[7] <= dataReceived[6];
      end

    assign miso = shiftReg[0];

endmodule




module dataCtrl(input logic cs, sck, 
					 input logic [7:0]spiDataIn,
                output logic setNewData,
					 output logic [7:0] addressOut);

    logic [10:0] bitCount;
	 
	 logic byteOut;
	 logic byteOutNegEdge;
	 logic andOut;	// somewhat unecessary intermediate wire name.
    assign andOut = bitCount[2] & bitCount[1] & bitCount[0];

      
      always_ff @ (posedge sck, posedge cs)
    begin
        if (cs)
    begin
            bitCount <= 5'b0000;
				byteOut <= 1'b1;
        end
        else
        begin
    bitCount <= bitCount + 5'b0001;
    byteOut <= andOut;
        end
    end
	 
	 
	 
	 
	 
	 always_ff @ (negedge sck, posedge cs)
	 begin
        if (cs)
		      byteOutNegEdge <= 1'b1;
		  else
				byteOutNegEdge <= byteOut;
	 end
	 
	 always_latch
	 begin
        if (byteOutNegEdge)
		  begin
		      setNewData<= byteOut;
		  end
	 end
	 
	
	
	 logic lockBaseAddress;
    logic writeEnableTrigger;
    logic [7:0] offset;
	 
    always_ff @ (posedge byteOut, posedge cs)
    begin
      if (cs)
            offset <= -8'b00000001;
        else
            begin
                offset <= offset + 8'b00000001;
            end
    end
  

  
    always_ff @ (posedge byteOutNegEdge, posedge cs)
    begin
        if (cs)
		      lockBaseAddress <= 1'b0;
		  else
		  lockBaseAddress <= 1'b1;
    end
		
															
  logic byteOutCtrl;
  assign byteOutCtrl = byteOut & ~lockBaseAddress;
  
  always_ff @ (posedge byteOutNegEdge, posedge byteOutCtrl)
  begin
      if (byteOutCtrl)
			addressOut<= spiDataIn;
		else
			addressOut <= addressOut + 8'b0000001;
  end
  
endmodule

