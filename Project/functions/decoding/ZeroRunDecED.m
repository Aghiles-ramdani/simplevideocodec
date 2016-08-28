function zigzag_block = ZeroRunDecED(zre_blk, width, height, isBframe)

    EOF = 700; %End of File value
    
    if (isBframe == 1)
        num_vals = width*height*2.125;
    else
        num_vals = width*height*3;
    end
    
    %Output block
    zigzag_block = zeros(1,(num_vals));
    %Position in input block
    zre_pos = 1;
    
    %Zero Run Decode
    for t = 1 : 64 : num_vals
        
        %Block to populate
        block = zeros(1, 64);
        block_pos = 1;
        
        while(block_pos <= 64)
        
            %If there is a zero at the position move the position the number of
            %counted zeros forward
            if(zre_blk(zre_pos) == 0)
                zre_pos = zre_pos + 1;
                block_pos = block_pos + zre_blk(zre_pos) + 1;
                zre_pos = zre_pos + 1;

            %If EOF reached then the rest of the block is 0s terminate
            elseif(zre_blk(zre_pos) == EOF)
                zre_pos = zre_pos + 1;
                break

            %A non zero value is reached
            else
                block(block_pos) = zre_blk(zre_pos);
                zre_pos = zre_pos + 1;
                block_pos = block_pos + 1;
            end
        
        end
        
        %Add the values to the new stream
        zigzag_block(t : t+63) = block;
                   
    end    

end