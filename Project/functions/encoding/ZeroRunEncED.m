function zre_blk = ZeroRunEncED(zigzag_block)

    EOF = 700; %End of File value

    zre_blk = zeros(1, length(zigzag_block));

    zre_pos = 1; %position within zre_blk
    
    %iterate through each block of 64 and perform zero run encode
    for i = 1 : 64: length(zigzag_block)
        
        %Grab Block on which to perform
        block = zigzag_block(i:i+63);
        
        %perform zero run encode on block
        cnt = 0;
        for j = 1 : 64
            
            %If 0 at the positition increment the counter
            if(block(j) == 0)
                cnt = cnt + 1;
                
            %If non zero and counter greater than 0 add counted zeros plus
            %non zero number
            elseif(cnt > 0)
                zre_blk(zre_pos+1) = cnt-1;
                zre_blk(zre_pos+2) = block(j);
                cnt = 0;
                zre_pos = zre_pos + 3;
                
            %If multiple non zero one after the other just add the non zero
            %values in as they are parsed
            else
                zre_blk(zre_pos) = block(j);
                zre_pos = zre_pos + 1;
            end
            
        end
        
        %if the end of the for loop is reached and cnt is non zero then
        %there must have been a string of ending 0s add EOF
        if (cnt > 0)
            zre_blk(zre_pos) = EOF;
            zre_pos = zre_pos + 1;
        end
       
    end
    
    zre_blk = zre_blk(1:zre_pos);
    
end