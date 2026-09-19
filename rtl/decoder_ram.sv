`include "./../verification/ram_if.sv"

module decoder_ram (
    ram_if.DUT vif
);

    logic [3:0] current_select;     // one-hot block select
    logic [4:0] word_address;       // index within the selected 32-word block

    integer i;

    assign word_address = vif.addr[4:0];

    // Decoder: top 2 bits of addr choose which memory block is active
    assign current_select[0] = (vif.addr[6:5] == 2'b00);
    assign current_select[1] = (vif.addr[6:5] == 2'b01);
    assign current_select[2] = (vif.addr[6:5] == 2'b10);
    assign current_select[3] = (vif.addr[6:5] == 2'b11);

    logic [7:0] mem_block0 [0:31];
    logic [7:0] mem_block1 [0:31];
    logic [7:0] mem_block2 [0:31];
    logic [7:0] mem_block3 [0:31];

    // ---------------- Write logic ----------------
    always @(posedge vif.clk or negedge vif.rst_n) begin
        if (!vif.rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                mem_block0[i] <= 8'b0;
                mem_block1[i] <= 8'b0;
                mem_block2[i] <= 8'b0;
                mem_block3[i] <= 8'b0;
            end
        end
        else if (vif.we) begin
            case (current_select)
                4'b0001: mem_block0[word_address] <= vif.wdata;
                4'b0010: mem_block1[word_address] <= vif.wdata;
                4'b0100: mem_block2[word_address] <= vif.wdata;
                4'b1000: mem_block3[word_address] <= vif.wdata;
                default: ; // no block selected, no write
            endcase
        end
    end

    // ---------------- Read logic ----------------
    always @(posedge vif.clk or negedge vif.rst_n) begin
        if (!vif.rst_n) begin
            vif.rdata <= 8'b0;
            vif.valid <= 1'b0;
        end
        else if (vif.re) begin
            case (current_select)
                4'b0001: vif.rdata <= mem_block0[word_address];
                4'b0010: vif.rdata <= mem_block1[word_address];
                4'b0100: vif.rdata <= mem_block2[word_address];
                4'b1000: vif.rdata <= mem_block3[word_address];
                default: vif.rdata <= 8'b0;
            endcase
            vif.valid <= 1'b1;
        end
        else begin
            vif.valid <= 1'b0;
        end
    end

endmodule