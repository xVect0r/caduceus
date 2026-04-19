module char_decode (
    input clk,
    input rstN,
    input [9:0] rxChar,
    input rxValid,

    output reg isNULL,
    output reg isFCT,
    output reg isEOP,
    output reg isEEP,
    output reg isNchar,
    output reg isTimecode,
    output reg [7:0] ncharData,
    output reg [7:0] timeData,
    output reg isInvalidChar
);

    reg prevEsc;

    localparam EOP = 8'b00000001;
    localparam EEP = 8'b00000010;
    localparam FCT = 8'b00000000;
    localparam ESC = 8'b00000011;

    always @(posedge clk) begin
        if (!rstN) begin
            isNULL <= 0;
            isFCT <= 0;
            isEOP <= 0;
            isEEP <= 0;
            isNchar <= 0;
            isTimecode <= 0;
            isInvalidChar <= 0;
            timeData <= 0;
            ncharData <= 0;
            prevEsc <= 0;
        end
        else begin
            if (rxValid) begin
                isNULL <= 0;
                isFCT <= 0;
                isEOP <= 0;
                isEEP <= 0;
                isNchar <= 0;
                isTimecode <= 0;
                isInvalidChar <= 0;
                ncharData <= 0;
                timeData <= 0;
                if (prevEsc) begin
                    if (rxChar[0] == 1'b1 && rxChar[8:1] == FCT) begin
                        isNULL <= 1'b1;
                    end
                    else if (rxChar[0] == 1'b1 && rxChar[8:1] != FCT &&
                             rxChar[8:1] != EOP && rxChar[8:1] != EEP && rxChar[8:1] != ESC) begin
                        isTimecode <= 1'b1;
                        timeData <= rxChar[8:1];
                    end
                    else begin
                        isInvalidChar <= 1'b1;
                    end
                    prevEsc <= 1'b0;
                end
                else begin
                    if (rxChar[0] == 1'b0) begin
                        isNchar <= 1'b1;
                        ncharData <= rxChar[8:1];
                    end
                    else begin
                        if (rxChar[8:1] == FCT) isFCT <= 1'b1;
                        else if (rxChar[8:1] == EOP) isEOP <= 1'b1;
                        else if (rxChar[8:1] == EEP) isEEP <= 1'b1;
                        else if (rxChar[8:1] == ESC) prevEsc <= 1'b1;
                        else isInvalidChar <= 1'b1;
                    end
                end
            end
            // else begin
            //     isNULL <= 0;
            //     isFCT <= 0;
            //     isEOP <= 0;
            //     isEEP <= 0;
            //     isNchar <= 0;
            //     isTimecode <= 0;
            //     isInvalidChar <= 0;
            //     timeData <= 0;
            //     ncharData <= 0;
            // end
        end
    end
endmodule