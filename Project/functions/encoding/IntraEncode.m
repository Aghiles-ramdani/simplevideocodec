function encoded = IntraEncode(im,n,zigzag_cor, C, s, a, isBframe)

    UseIntraEncoding = 0;

    %Decode the Data without Intra Encoding within the Frame
    if (UseIntraEncoding == 0)
        encoded =[];

        width = size(im,2);
        height = size(im,2);

        for k =1:3
            %Downsample Block
            if (k > 1 && isBframe == 1)
                tmp = resample(permute(resample(permute(padarray(im(:,:,k), [4 4], 'symmetric'), [2 1 3]),3,4), [2 1 3]),3,4);
                tmp = tmp(4:end-3, 4:end-3);
                cells = mat2cell(tmp, [ones(1,size(tmp,1)/8)*8], [ones(1,size(tmp,2)/8)*8]);
            else
                cells = mat2cell(im(:,:,k), [ones(1,size(im,1)/8)*8], [ones(1,size(im,2)/8)*8]);
            end
            enc = cellfun(@blk_transform,cells, 'UniformOutput', false);
            encoded = [encoded cell2mat(enc(:)')];
        end

        encoded = ZeroRunEncED(encoded);
        
    %Decode the Data when Intra Encoding is used within the Frames
    elseif (UseIntraEncoding == 1)
    
        %Matrix that holds the calculated prediction modes
        predmodes = zeros(1, (size(im,1)-8)*(size(im,2)-16)*1/8*1/8*3*3);
        %iterator for modes
        iter = 1;
        %Results
        Result = [];

        for k =1:3
        
            %Contains the encoded and then decoded values for prediction
            estimate = im(:,:,k);
            %encoded values that will be sent
            encoded = zeros(size(estimate));

            %grab first row
            cells = mat2cell(estimate(1:8,:), [8], [ones(1,size(im,2)/8)*8]);
            tmp = cellfun(@blockencode,cells, 'UniformOutput', false);   
            encoded(1:8, :) = cell2mat(tmp);
            cells = cellfun(@blockdecode,tmp, 'UniformOutput', false);
            estimate(1:8, :) = cell2mat(cells);

            %grab first column
            cells = mat2cell(estimate(9:end,1:8), [ones(1,size(im,1)/8-1)*8], [8]);
            tmp = cellfun(@blockencode,cells, 'UniformOutput', false); 
            encoded(9:end, 1:8) = cell2mat(tmp);
            cells = cellfun(@blockdecode,tmp, 'UniformOutput', false);
            estimate(9:end, 1:8) = cell2mat(cells);        

            %grab last column
            cells = mat2cell(estimate(9:end,end-7:end), [ones(1,size(im,1)/8-1)*8], [8]);
            tmp = cellfun(@blockencode,cells, 'UniformOutput', false); 
            encoded(9:end, end-7:end) = cell2mat(tmp);
            cells = cellfun(@blockdecode,tmp, 'UniformOutput', false);
            estimate(9:end, end-7:end) = cell2mat(cells);         

            %calculate the prediction values
            for row = 9 : 8 : size(im,1)
                for col = 9 : 8 : size(im,2)-8

                    %Create Estimate on 4*4 blocks
                    [pred1, mode1] = intrapredict(estimate(row-1:row+3, col-1:col+7));
                    estimate(row:row+3, col:col+3) = pred1;
                    [pred2, mode2] = intrapredict(estimate(row-1:row+3, col+3:col+11));
                    estimate(row:row+3, col+4:col+7) = pred2;
                    [pred3, mode3] = intrapredict(estimate(row+3:row+7, col-1:col+7));
                    estimate(row+4:row+7, col:col+3) = pred3;
                    pred4 = repmat(mean([estimate(row+3, col+4:col+7), estimate(row+4:row+7, col+3)']), [4 4]);             
                    estimate(row+4:row+7, col+4:col+7) = pred4;

                    %Calculate predicted values
                    midvals = im(row:row+7,col:col+7,k) - estimate(row:row+7, col:col+7);

                    %encode predicted values
                    encoded(row:row+7, col:col+7) = blockencode(midvals);

                    %decode predicted values
                    estimate(row:row+7, col:col+7) = blockdecode(encoded(row:row+7, col:col+7))+estimate(row:row+7, col:col+7);

                    predmodes(iter) = mode1;
                    predmodes(iter+1) = mode2;
                    predmodes(iter+2) = mode3;
                    iter = iter + 3; 
                end
            end

            %Perform Zig Zag
            cells = mat2cell(encoded, [ones(1,size(im,1)/8)*8], [ones(1,size(im,2)/8)*8]);
            enc = cellfun(@blockzigzag,cells, 'UniformOutput', false);
            Result = [Result cell2mat(enc(:)')];

        end

        encoded = ZeroRunEncED(Result);
        encoded = [predmodes, encoded];

    end

    %Perform full encode on a block
    function zigzag_block  = blk_transform(blk)
        DCT_blk = DCT8x8(blk, C, s, a);
        quant_blk = Quant8x8(DCT_blk, k,n);
        zigzag_block = ZigZag8x8(quant_blk, zigzag_cor);
    end

    %Perform Encode
    function encblk  = blockencode(blk)
        DCT_blk = DCT8x8(blk, C, s, a);  
        encblk = Quant8x8(DCT_blk, k,n);
    end

    %Perform Decode
    function decblk  = blockdecode(blk)
        DCT_blk = DeQuant8x8(blk,k,n);
        decblk = IDCT8x8(DCT_blk, C, s, a);
    end  

    %Perform ZigZag encode
    function zigzag_block = blockzigzag(blk)
        zigzag_block = ZigZag8x8(blk, zigzag_cor);
    end

    %Function that calculates the most appropriate prediction mode
    function [prediction, mode] = intrapredict(block)
        
        SAE = 1000000;
        
        for o = 0 : 8
            
            switch o
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
            
            sae = sum(sum(abs(block(2:5, 2:5) - est)));
            if sae < SAE
                SAE = sae;
                mode = o;
                prediction = est;
            end             
        end
    end
end
