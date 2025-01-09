module Uart_Byte_RX
       #
       (
           parameter [31: 0]BAUD_RATE = 32'd921600
       )
       (
           input clk_100M,
           input rst_n,

           input RX,

           output reg[7: 0]data_byte,
           // 上升沿接收完成
           output reg irq
       );

// Uart字节接收
// 数据位 8
// 停止位 1
// 奇偶校验位 None

localparam [31: 0] BAUD_SET = (100_000_0000 / BAUD_RATE + 5) / 10;

// wire
wire RX_sync;

wire clk_baud;
wire [31: 0]cnt_baud;

// reg
reg RX_sync_pre;

reg receive;

reg irq_reg;
reg irq_pre;

reg [8: 0]data_byte_reg;

// 同步链
Sync_Chain Sync_Chain_inst
           (
               .clk_100M(clk_100M) ,
               .rst_n(rst_n) ,
               .sig(RX) ,
               .sig_sync(RX_sync)
           );

// 接收使能
always@(posedge clk_100M or negedge rst_n)
begin
	if (!rst_n)
	begin
		receive <= 1'd0;
		RX_sync_pre <= 1'd0;
		irq_pre <= 1'd0;
	end
	else
	begin
		RX_sync_pre <= RX_sync;
		irq_pre <= irq;

		if (RX_sync_pre && !RX_sync) //RX下降沿
		begin
			receive <= 1'd1;
		end
		else
		begin
			if (!irq_pre && irq) //接收完成上升沿
			begin
				receive <= 1'd0;
			end
			else
			begin
				if (cnt_baud == 32'd1 && data_byte_reg[0] != 1'd0) //非起始位
				begin
					receive <= 1'd0;
				end
			end
		end
	end
end

// 波特时钟
Clk_Div #(BAUD_SET, BAUD_SET[31: 1])Clk_Div_inst
        (
            .clk(clk_100M) ,
            .rst_n(rst_n) ,
            .phase_rst(~receive) ,
            .clk_div(clk_baud) ,
            .cnt()
        );

// 码元计数
Clk_Div #(32'd10, 32'd5)Clk_Div_inst2
        (
            .clk(clk_baud) ,
            .rst_n(rst_n) ,
            .phase_rst(~receive) ,
            .clk_div() ,
            .cnt(cnt_baud)
        );

always@(negedge clk_baud or negedge rst_n)
begin
	if (!rst_n)
	begin
		irq_reg <= 1'd0;

		data_byte_reg <= 1'd0;
		data_byte <= 1'd0;
	end
	else
	begin
		case (cnt_baud) //接收LSB
			0, 1, 2, 3, 5, 6, 7, 8:
			begin
				data_byte_reg[cnt_baud] <= RX_sync;
			end
			4:
			begin
				irq_reg <= 1'd0;

				data_byte_reg[cnt_baud] <= RX_sync;
			end
			9:
			begin
				if (RX_sync == 1'd1) //停止位
				begin
					data_byte <= data_byte_reg[8: 1];

					irq_reg <= 1'd1;
				end
			end
			default:
				;
		endcase
	end
end

always@(posedge clk_100M or negedge rst_n)
begin
	if (!rst_n)
	begin
		irq <= 1'd0;
	end
	else
	begin
		irq <= irq_reg;
	end
end

endmodule
