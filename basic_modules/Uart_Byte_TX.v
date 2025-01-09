module Uart_Byte_TX
       #
       (
           parameter [31: 0]BAUD_RATE = 32'd921600
       )
       (
           input clk_100M,
           input rst_n,

           input [7: 0]data_byte,
           // 上升沿发送
           input transmit_en,

           output reg TX,
           // 上升沿发送完成
           output irq
       );

// Uart字节发送
// 数据位 8
// 停止位 1
// 奇偶校验位 None

localparam [31: 0] BAUD_SET = (100_000_0000 / BAUD_RATE + 5) / 10;

// wire
wire clk_baud;
wire [31: 0]cnt_baud;

// reg
reg transmit_en_pre;
reg transmit;

reg [9: 0]data_byte_reg;

reg irq_pre;

// 发送使能
always@(posedge clk_100M or negedge rst_n)
begin
	if (!rst_n)
	begin
		transmit <= 1'd0;

		transmit_en_pre <= 1'd0;
		irq_pre <= 1'd0;

		data_byte_reg <= 1'd0;
	end
	else
	begin
		transmit_en_pre <= transmit_en;
		irq_pre <= irq;

		if (!transmit_en_pre && transmit_en) //发送使能上升沿
		begin
			transmit <= 1'd1;

			data_byte_reg <= {1'b1, data_byte, 1'b0}; //起始位、停止位
		end
		else
		begin
			if (!irq_pre && irq) //发送完成上升沿
			begin
				transmit <= 1'd0;
			end
		end
	end
end

// 波特时钟
Clk_Div #(BAUD_SET, BAUD_SET[31: 1])Clk_Div_inst
        (
            .clk(clk_100M) ,
            .rst_n(rst_n) ,
            .phase_rst(~transmit) ,
            .clk_div(clk_baud) ,
            .cnt()
        );

// 码元计数
Clk_Div #(32'd10, 32'd5)Clk_Div_inst2
        (
            .clk(clk_baud) ,
            .rst_n(rst_n) ,
            .phase_rst(~transmit) ,
            .clk_div(irq) ,
            .cnt(cnt_baud)
        );

always@(negedge clk_baud or negedge rst_n)
begin
	if (!rst_n)
	begin
		TX <= 1'd1;
	end
	else
	begin
		case (cnt_baud) //发送LSB
			0, 1 , 2, 3, 4, 5, 6, 7, 8, 9:
				TX <= data_byte_reg[cnt_baud];
			default:
				TX <= 1'd1;
		endcase
	end
end

endmodule
