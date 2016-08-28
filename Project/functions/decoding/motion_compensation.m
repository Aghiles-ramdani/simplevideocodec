function rec_image = motion_compensation(im_ref, err_im, MV)

    %Get Image size
    [width, height, ~] = size(im_ref);

    pos_x = (reshape(MV(1:(size(MV,2)/2)), [width/8 height/8]));
    pos_y = (reshape(MV((size(MV,2)/2)+1:end), [width/8 height/8]));

    im_pel = imresize(im_ref, 2, 'bilinear');
    n = 8;%size of the blocks for the motion vectors
    %intialise the size of the image est to avoid loops and such
    img_est = zeros(size(im_ref,1), size(im_ref,2), size(im_ref,3));
    for j= 1:8:(size(im_ref,1))
        for i=1:8:(size(im_ref,2))
            MV = [pos_y(ceil(j/n),ceil(i/n)) pos_x(ceil(j/n),ceil(i/n))];
            if(mod(2*MV(1),2) == 0 && mod(2*MV(2),2) == 0)
                %Assign image estimate based on the reference image
                img_est(j:j+7, i:i+7,:) = im_ref(j+MV(1):j+MV(1)+7, i+MV(2):i+MV(2)+7,:);
            else
                img_est(j:j+7, i:i+7,:) = im_pel(2*(j+MV(1)):2*(j+MV(1))+7, 2*(i+MV(2)):2*(i+MV(2))+7,:);
            end
        end
    end
    %Use error image and estimate to reconstruct rec_image
    rec_image = err_im + img_est;

end