module UartFrameRX
       #
       (
           parameter [31: 0]BAUD_RATE = 32'd921600
       )
       (
           input clk_100M,
           input rst_n,

           input RX,

           output reg[23: 0]data_frame,
           // 上升沿接收完成
           output reg irq
       );

// Uart帧接收
// 帧 data_frame[23:0] 3+ff
// 数据位 8
// 停止位 1
// 奇偶校验位 None

// wire
wire [7: 0]data_byte;
wire byte_rx_irq;

// reg
reg byte_rx_irq_pre;

reg [39: 0]data_frame_reg;

reg irq_reg;

always@(posedge clk_100M or negedge rst_n)
begin
	if (!rst_n)
	begin
		byte_rx_irq_pre <= 1'd0;

		data_frame_reg <= 1'd0;
		data_frame <= 1'd0;

		irq_reg <= 1'd0;
		irq <= 1'd0;
	end
	else
	begin
		byte_rx_irq_pre <= byte_rx_irq;

		if (!byte_rx_irq_pre && byte_rx_irq) //字节接收上升沿
		begin
			if (data_frame_reg[15: 0] == 16'hffff && data_byte == 8'hff) //帧尾
			begin
				data_frame <= data_frame_reg[39: 16];
				data_frame_reg <= 1'd0;

				irq_reg <= 1'd1;
			end
			else
			begin
				data_frame_reg <= {data_frame_reg[31: 0], data_byte}; //字节左移

				irq_reg <= 1'd0;
			end
		end

		irq <= irq_reg;
	end
end

// 字节接收
Uart_Byte_RX #(BAUD_RATE)Uart_Byte_RX_inst
             (
                 .clk_100M(clk_100M) ,
                 .rst_n(rst_n) ,
                 .RX(RX) ,
                 .data_byte(data_byte) ,
                 .irq(byte_rx_irq)
             );

endmodule
