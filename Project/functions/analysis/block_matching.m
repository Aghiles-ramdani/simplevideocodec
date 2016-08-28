function [pos_x, pos_y] =block_matching(im, cur_blk, srch_pos)
    srch_range = 4;
    pos_x = 1;
    pos_y = 1;
    min_SAD = 256^12;
    %perform search over the search area
    for j= (srch_pos(1)-srch_range):(srch_range+srch_pos(1))
        for i= (srch_pos(2)-srch_range):(srch_range+srch_pos(2))
            %Check if the image is contained with image itself
            if(i > 0 && j > 0 && (i+7) <= size(im,2) && (j+7) <= size(im,1))
                
                blk = im(j:(j+7), i:(i+7));
                SAD = sum(sum(abs(cur_blk-blk)));
                if(SAD < min_SAD) 
                    min_SAD = SAD;
                    pos_x = i-srch_pos(2);
                    pos_y = j-srch_pos(1);
                end
            end
        end
    end

end