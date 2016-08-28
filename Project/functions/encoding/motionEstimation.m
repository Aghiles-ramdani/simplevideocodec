function [err_im, MV] = motionEstimation(im_ref, im)

    im_pel = imresize(im_ref, 2, 'bilinear');
    pos_x = zeros(size(im,1)/8, size(im,2)/8);
    pos_y = zeros(size(im,1)/8, size(im,2)/8);
    img_est = zeros(size(im,1), size(im,2), size(im,3));
    for j= 1:8:(size(im,1))
        for i=1:8:(size(im,2))
            cur_blk = im(j:j+7, i:i+7,1); 
            srch_pos = [j i];
            [pos_1, pos_2, opt_blk] = log_search(im_ref, cur_blk, srch_pos, im_pel);
            img_est(j:j+7,i:i+7,:) = opt_blk;
            [pos_x(ceil(j/8), ceil(i/8))]= pos_1; 
            [ pos_y(ceil(j/8), ceil(i/8))] = pos_2;
        end
    end
    MV = cat(3,pos_x, pos_y);

    %Save data for generating huffman table for movement vectors
% % %     load('thenum')
% % %     save(sprintf('data/mvdata/mv%d.mat', thenum), 'MV')
% % %     thenum = thenum + 1;
% % %     save('thenum.mat', 'thenum')
    
    err_im = im - img_est;
    
end