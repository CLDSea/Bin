module FIFO
		 (
			 input clk_100M,
			 input rst_n,

			 input wr_en,
			 input wr_clk,

			 input rd_en,
			 input rd_clk,

			 input [data_bit_width - 1: 0]data_fifo_in,

			 output reg wr_full,
			 output reg rd_empty,
			 output reg [data_bit_width - 1: 0]data_fifo_out = 1'd0
		 );


parameter [31: 0]data_bit_width = 32'd12; //数据位宽
parameter [31: 0]data_bit_depth = 32'd10; //数据位深
parameter [31: 0]data_depth = 32'd1000; //数据深度

reg [data_bit_width - 1: 0]ram[1 << data_bit_depth - 1: 0];
reg [data_bit_depth - 1: 0]wr_addr = 1'd0;
reg [data_bit_depth - 1: 0]rd_addr = 1'd0;

reg wr_en_pre = 1'd0;
reg rd_en_pre = 1'd0;

reg wr = 1'd0;
reg rd = 1'd0;

always@(posedge clk_100M or negedge rst_n)
begin
	if (!rst_n)
	begin
		wr <= 1'd0;
		rd <= 1'd0;
		wr_en_pre <= 1'd0;
		rd_en_pre <= 1'd0;
	end
	else
	begin
		wr_en_pre <= wr_en;
		rd_en_pre <= rd_en;

		if ((!rd_en_pre && rd_en) && wr_full) //写满且读使能上升沿开始读
		begin
			wr <= 1'd0;
			rd <= 1'd1;
		end
		else if ((!wr_en_pre && wr_en) && rd_empty) //读满且写使能上升沿开始写
		begin
			wr <= 1'd1;
			rd <= 1'd0;
		end
	end
end

always@(posedge wr_clk or posedge rd or negedge rst_n)
begin
	if(!rst_n)
	begin
		wr_addr<=1'd0;
		wr_full<=1'd0;
	end
	else
	begin
		if(rd)
		begin
			wr_full<=1'd0;
		end
		else
		begin
			if(wr&&!wr_full)//未写满且写
			begin
				ram[wr_addr]<=data_fifo_in;
				
				if (wr_addr < data_depth - 1'd1)
				begin
					wr_addr <= wr_addr + 1'd1;
				end
				else
				begin
					wr_addr<=1'd0;
					wr_full<=1'd1;
				end
			end
		end
	end
end

always@(posedge rd_clk or posedge wr or negedge rst_n)
begin
	if(!rst_n)
	begin
		rd_addr<=1'd0;
		rd_empty<=1'd1;
	end
	else
	begin
		if(wr)
		begin
			rd_empty<=1'd0;
		end
		else
		begin
			if(rd&&!rd_empty)//未读空且读
			begin
				data_fifo_out<=ram[rd_addr];
				
				if (rd_addr < data_depth - 1'd1)
				begin
					rd_addr <= rd_addr + 1'd1;
				end
				else
				begin
					rd_addr<=1'd0;
					rd_empty<=1'd1;
				end
			end
		end
	end
end

endmodule