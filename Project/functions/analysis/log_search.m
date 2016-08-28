function [pos_x, pos_y, opt_blk] = log_search(im, cur_blk, srch_pos, im_pel)
    srch_range = 4;
    pos_x = srch_pos(2);
    pos_y = srch_pos(1);
    %Create the intial stage search at point [0, 0]
    blk = im(pos_y:(pos_y+7), pos_x:(pos_x+7));
    min_SAD = sum(sum(abs(cur_blk-blk)));
    
    srch_finish = 0;
    pos_dis = 2;
    pos_arr_2 = [0 -2; 0 2; -2 0; 2 0];
    pos_arr_1 = [1 -1; 0 -1; -1 -1; 1 0; 0 0;-1 0; 1 1; 0 1; -1 1];
    %Perform iterations of log search
    while(srch_finish == 0)
        %Large search on coordinates plus 2 away from each instance
        if(pos_dis == 2)
            SAD = 256^12*ones(1,4);
            for i= 1:4
                cor_x = pos_x+pos_arr_2(i,2);
                cor_y = pos_y+pos_arr_2(i,1);
                if(cor_x > 0 && cor_y > 0 && (cor_x+7) <= size(im,2) && (cor_y+7) <= size(im,1))
                    if(abs(cor_x-srch_pos(2)) <= srch_range && abs(cor_y-srch_pos(1)) <= srch_range)
                        blk = im(cor_y:(cor_y+7), cor_x:(cor_x+7), 1);
                        SAD(i) = sum(sum(abs(cur_blk-blk)));
                    end
                end
            end

            if(min(SAD) < min_SAD)
                [min_SAD I] = min(SAD);
                pos_x = pos_x + pos_arr_2(I,2);
                pos_y = pos_y + pos_arr_2(I,1);
                if(min_SAD == 0)
                    srch_finish = 1;
                    opt_blk = im(pos_y:(pos_y+7), pos_x:(pos_x+7),:);
                end
            else
                pos_dis = 1;
            end
        %Refine the search to a radius of 1 
        elseif(pos_dis == 1)
            SAD = 256^12*ones(1,9);
            for i = 1:8
                cor_x = pos_x+pos_arr_1(i,2);
                cor_y = pos_y+pos_arr_1(i,1);
                if(cor_x > 0 && cor_y > 0 && (cor_x+7) <= size(im,2) && (cor_y+7) <= size(im,1))
                    if(abs(cor_x-srch_pos(2)) <= srch_range && abs(cor_y-srch_pos(1)) <= srch_range)
                        blk = im(cor_y:(cor_y+7), cor_x:(cor_x+7), 1);
                        SAD(i) = sum(sum(abs(cur_blk-blk)));
                    end
                end
            end
            [min_SAD I] = min(SAD);
            pos_x = pos_x + pos_arr_1(I,2);
            pos_y = pos_y + pos_arr_1(I,1);
            if(min_SAD == 0)
                srch_finish = 1;
                opt_blk = im(pos_y:(pos_y+7), pos_x:(pos_x+7), :);
            end
            pos_dis = 1/2;
        %Perform the half pel accuracy motion estimation
        else
            pos_x_pel = 2*pos_x;
            pos_y_pel = 2*pos_y;
            SAD = 256^12*ones(1,9);
            
            for i = 1:8
                cor_x = pos_x_pel+pos_arr_1(i,2);
                cor_y = pos_y_pel+pos_arr_1(i,1);
                if(cor_x > 0 && cor_y > 0 && (cor_x+7) <= size(im_pel,2) && (cor_y+7) <= size(im_pel,1))
                    if(abs(cor_x-2*srch_pos(2)) <= 2*srch_range && abs(cor_y-2*srch_pos(1)) <= 2*srch_range)
                        blk = im_pel(cor_y:(cor_y+7), cor_x:(cor_x+7), 1);
                        SAD(i) = sum(sum(abs(cur_blk-blk)));
                    end
                end
            end
            
            if(min(SAD) < min_SAD)
                [min_SAD I] = min(SAD);
                pos_x = pos_x + pos_arr_1(I,2)/2;
                pos_y = pos_y + pos_arr_1(I,1)/2;
                opt_blk = im_pel(2*pos_y:(2*pos_y+7), 2*pos_x:(2*pos_x+7), :);
            else
                opt_blk = im(pos_y:(pos_y+7), pos_x:(pos_x+7), :);
            end
            
            srch_finish = 1;
        end
    end
    pos_x = pos_x - srch_pos(2);
    pos_y = pos_y - srch_pos(1);       
end