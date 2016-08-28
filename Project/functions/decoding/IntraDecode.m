function decoded = IntraDecode(im, width, height, n, zigzag_cor, C, s, a, isBframe)

    UseIntraEncoding = 0;

    %Decode the Data without Intra Encoding within the Frame
    if (UseIntraEncoding == 0)
        decoded =[];
        zigzag_block = ZeroRunDecED(im, width , height, isBframe);

        for k =1:3
            %Upsample Block
            if (k > 1 && isBframe == 1)
                h = 3/4*height;
                w = 3/4*width;
            %No Upsampling Required
            else
                h = height;
                w = width;
            end

            cnt = 1;
            dec_blk = zigzag_block(((w*h)*(k-1))+1:k*(w*h));
            cell_input = mat2cell(dec_blk, [1], [ones(1,size(dec_blk,2)/64)*64]);
            output = cellfun(@split_block,cell_input,'UniformOutput', false);
            cells = reshape(output, [w/8 h/8]);
            dec = cellfun(@blk_transform,cells, 'UniformOutput', false);
            %Upsample Block
            if (k > 1 && isBframe == 1)
                temp = resample(permute(resample(permute(padarray(cell2mat(dec), [3 3], 'symmetric'), [2 1 3]),4,3), [2 1 3]),4,3);
                dec = temp(5:end-4, 5:end-4);
            %No Upsampling Required
            else
                dec = cell2mat(dec);
            end
            decoded = cat(3,decoded ,dec);
        end
    
    %Decode the Data when Intra Encoding is used within the Frames
    elseif (UseIntraEncoding == 1)

        decoded =[];

        %Extract the mode values from the stream
        predmodes = im(1:(width-8)*(height-16)*1/8*1/8*3*3);

        im = im((width-8)*(height-16)*1/8*1/8*3*3+1:end);

        zigzag_block = ZeroRunDecED(im, width , height, isBframe);
        iter = 1;

        temp = [];

        for k =1:3
            %Upsample Block
            if (k > 1 && isBframe == 1)
                h = 3/4*height;
                w = 3/4*width;
            %No Upsampling Required
            else
                h = height;
                w = width;
            end

            cnt = 1;
            dec_blk = zigzag_block(((w*h)*(k-1))+1:k*(w*h));
            cells = cell(h/8,w/8);
            cell_input = mat2cell(dec_blk, [1], [ones(1,size(dec_blk,2)/64)*64]);
            output = cellfun(@split_block,cell_input,'UniformOutput', false);
            cells = reshape(output, [w/8 h/8]);
            dec = cellfun(@blk_transform,cells, 'UniformOutput', false);

            %Upsample Block
            if (k > 1 && isBframe == 1)
                temp = resample(permute(resample(permute(padarray(cell2mat(dec), [3 3], 'symmetric'), [2 1 3]),4,3), [2 1 3]),4,3);
                dec = temp(5:end-4, 5:end-4);
            %No Upsampling Required
            else
                dec = cell2mat(dec);
            end

            temp = cat(3,temp ,dec);
            estblock = zeros(9,13);
            %add intraprediction back to values
            for row = 9 : 8 : w
                for col = 9 : 8 : h-8

                    %Set up est block with reference values
                    estblock(:,1) = dec(row-1:row+7, col-1);
                    estblock(1,:) = dec(row-1, col-1:col+11);

                    %Create Estimate on 4*4 blocks
                    estblock(2:5, 2:5) = intrapredict(estblock(1:5, 1:9), predmodes(iter));
                    iter = iter + 1;
                    estblock(2:5, 6:9) = intrapredict(estblock(1:5, 5:13), predmodes(iter));
                    iter = iter + 1;
                    estblock(6:9, 2:5) = intrapredict(estblock(5:9, 1:9), predmodes(iter));
                    iter = iter + 1;
                    estblock(6:9, 6:9) = intrapredict(estblock(5:9, 5:13), 2);

                    dec(row:row+7, col:col+7) = dec(row:row+7, col:col+7) + estblock(2:9,2:9);
                end
            end


            decoded = cat(3,decoded ,dec);
        end

    end
    
    function dec_blk= blk_transform(zigzag_blk)
        quant_blk = DeZigZag8x8(zigzag_blk, zigzag_cor);
        DCT_blk = DeQuant8x8(quant_blk,k,n);
        blk = IDCT8x8(DCT_blk, C, s, a);
        dec_blk = blk;
    end

    function cell_rshp = split_block(input)
        cell_rshp = reshape(input, [8 8]);
        cnt = cnt + 1;
    end

    function prediction = intrapredict(block, mode)   
            
        switch mode
            case 0 %vertical
                est = repmat(block(1, 2:5),[4 1]);                                     

            case 1 %horizontal
                est = repmat(block(2:5, 1),[1 4]);

            case 2 %DC
                DC = mean([block(1, 2:5), block(2:5, 1)']);
%                     DC = round(mean([block(1, 2:5), block(2:5, 1)' 4]));
                est = repmat(DC,[4 4]);

            case 3 %Diagonal Down-Left
                est = [block(1, 3) block(1, 4) block(1, 5) block(1, 6);
                       block(1, 4) block(1, 5) block(1, 6) block(1, 7);
                       block(1, 5) block(1, 6) block(1, 7) block(1, 8);
                       block(1, 6) block(1, 7) block(1, 8) block(1, 9)];
%                     v1 = (block(1, 2)+2*block(1, 3)+block(1, 4)+2)/4;
%                     v2 = (block(1, 3)+2*block(1, 4)+block(1, 5)+2)/4;
%                     v3 = (block(1, 4)+2*block(1, 5)+block(1, 6)+2)/4;
%                     v4 = (block(1, 5)+2*block(1, 6)+block(1, 7)+2)/4;
%                     v5 = (block(1, 6)+2*block(1, 7)+block(1, 8)+2)/4;
%                     v6 = (block(1, 7)+2*block(1, 8)+block(1, 9)+2)/4;
%                     v7 = (block(1, 8)+3*block(1, 9)+2)/4;
% 
%                     est = [v1 v2 v3 v4;
%                            v2 v3 v4 v5;
%                            v3 v4 v5 v6;
%                            v4 v5 v6 v7];

            case 4 %Diagonal Down-Right
                est = [block(1, 1) block(1, 2) block(1, 3) block(1, 4);
                       block(2, 1) block(1, 1) block(1, 2) block(1, 3);
                       block(3, 1) block(2, 1) block(1, 1) block(1, 2);
                       block(4, 1) block(3, 1) block(2, 1) block(1, 1)];
%                     v1 = (block(5, 1)+2*block(4, 1)+block(3, 1)+2)/4;
%                     v2 = (block(4, 1)+2*block(3, 1)+block(2, 1)+2)/4;
%                     v3 = (block(3, 1)+2*block(2, 1)+block(1, 1)+2)/4;
%                     v4 = (block(2, 1)+2*block(1, 1)+block(1, 2)+2)/4;
%                     v5 = (block(1, 1)+2*block(1, 2)+block(1, 3)+2)/4;
%                     v6 = (block(1, 2)+2*block(1, 3)+block(1, 4)+2)/4;
%                     v7 = (block(1, 3)+2*block(1, 4)+block(1,5)+2)/4;
% 
%                     est = [v4 v5 v6 v7;
%                            v3 v4 v5 v6;
%                            v2 v3 v4 v5;
%                            v1 v2 v3 v4];

            case 5 %Vertical-Right
                est = [mean(block(1, 1:2)) mean(block(1, 2:3)) mean(block(1, 3:4)) block(1, 4);
                       block(1, 1) block(1, 2) block(1, 3) block(1, 4);
                       mean(block(1:2:3, 1)) mean(block(1, 1:2)) mean(block(1, 2:3)) block(1, 3);
                       block(3, 1) block(1, 1) block(1, 2) block(1, 3)];
%                     v1 = (block(1, 1)+block(1, 2)+1)/2;
%                     v2 = (block(1, 2)+block(1, 3)+1)/2;
%                     v3 = (block(1, 3)+block(1, 4)+1)/2;
%                     v4 = (block(1, 4)+block(1, 5)+1)/2;
%                     v5 = (block(2, 1)+2*block(1, 1)+block(1, 2)+2)/4;
%                     v6 = (block(1, 1)+2*block(1, 2)+block(1, 3)+2)/4;
%                     v7 = (block(1, 2)+2*block(1, 3)+block(1,4)+2)/4;
%                     v8 = (block(1, 3)+2*block(1, 4)+block(1,5)+2)/4;
%                     v9 = (block(1, 1)+2*block(2, 1)+block(3,1)+2)/4;
%                     v10 = (block(2, 1)+2*block(3, 1)+block(4,1)+2)/4;
% 
%                     est = [v1 v2 v3 v4;
%                            v5 v6 v7 v8;
%                            v9 v1 v2 v3;
%                            v10 v5 v6 v7];

            case 6 %Horizontal-Down
                est = [mean(block(1:2, 1)) block(1, 1) mean(block(1, 1:2:3)) block(1, 3);
                       mean(block(2:3, 1)) block(2, 1) mean(block(1:2, 1)) block(1, 1);
                       mean(block(3:4, 1)) block(3, 1) mean(block(2:3, 1)) block(2, 1);
                       block(4, 1) block(4, 1) block(3, 1) block(3, 1)];
%                     v1 = (block(1, 1)+block(2, 1)+1)/2;
%                     v2 = (block(2, 1)+2*block(1, 1)+block(1,2)+2)/4;
%                     v3 = (block(1, 1)+2*block(1, 2)+block(1,3)+2)/4;
%                     v4 = (block(1, 2)+2*block(1, 3)+block(1,4)+2)/4;
%                     v5 = (block(2, 1)+block(2, 1)+1)/2;                    
%                     v6 = (block(1, 1)+2*block(2, 1)+block(3,1)+2)/4;
%                     v7 = (block(3, 1)+block(4, 1)+1)/2;                    
%                     v8 = (block(2, 1)+2*block(3, 1)+block(4,1)+2)/4;
%                     v9 = (block(4, 1)+block(5, 1)+1)/2;                    
%                     v10 = (block(3, 1)+2*block(4, 1)+block(5,1)+2)/4;
% 
%                     est = [v1 v2 v3 v4;
%                            v5 v6 v1 v2;
%                            v7 v8 v5 v6;
%                            v9 v10 v7 v8];

            case 7 %Vertical_Left
                est = [block(1, 3) mean(block(1, 3:4)) mean(block(1, 4:5)) mean(block(1, 5:6));
                       block(1, 3) block(1, 4) block(1, 5) block(1, 6);
                       block(1, 4) mean(block(1, 4:5)) mean(block(1, 5:6)) mean(block(1, 6:7));
                       block(1, 4) block(1, 5) block(1, 6) block(1, 7)];
%                     v1 = (block(1, 2)+block(1, 3)+1)/2;
%                     v2 = (block(1, 3)+block(1, 4)+1)/2;
%                     v3 = (block(1, 4)+block(1, 5)+1)/2;
%                     v4 = (block(1, 5)+block(1, 6)+1)/2;
%                     v5 = (block(1, 6)+block(1, 7)+1)/2;
%                     v6 = (block(1, 2)+2*block(1, 3)+block(1,4)+2)/4;
%                     v7 = (block(1, 3)+2*block(1, 4)+block(1,5)+2)/4;
%                     v8 = (block(1, 4)+2*block(1, 5)+block(1,6)+2)/4;
%                     v9 = (block(1, 5)+2*block(1, 6)+block(1,7)+2)/4;
%                     v10 = (block(1, 6)+2*block(1, 7)+block(1,8)+2)/4;
%                     
%                     est = [v1 v2 v3 v4;
%                            v6 v7 v8 v9;
%                            v2 v3 v4 v5;
%                            v7 v8 v9 v10];


            case 8 %Horizontal-Up
                est = [block(2, 1) mean(block(2:3, 1)) block(3, 1) block(3, 1);
                       block(3, 1) mean(block(3:4, 1)) block(4, 1) block(4, 1);
                       block(4, 1) mean(block(4:5, 1)) block(5, 1) block(5, 1);
                       block(5, 1) block(5, 1) block(5, 1) block(5, 1)];
%                     v1 = (block(2, 1)+block(3, 1)+1)/2;
%                     v2 = (block(2, 1)+2*block(3, 1)+block(4,1)+2)/4;
%                     v3 = (block(3, 1)+block(4, 1)+1)/2;
%                     v4 = (block(3, 1)+2*block(4, 1)+block(5,1)+2)/4;
%                     v5 = (block(4, 1)+block(5, 1)+1)/2;
%                     v6 = (block(4, 1)+3*block(5, 1)+2)/4;
%                     v7 = block(5, 1);
%                     
%                     est = [v1 v2 v3 v4;
%                            v3 v4 v5 v6;
%                            v5 v6 v7 v7;
%                            v7 v7 v7 v7];

        end

        prediction = est;
             
    end
    
end