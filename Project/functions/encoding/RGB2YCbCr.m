function CT_image = RGB2YCbCr(im_in)

    Y = 0.299*im_in(:,:,1) + 0.587*im_in(:,:,2) + 0.114*im_in(:,:,3);
    Cb = -0.169*im_in(:,:,1) - 0.331*im_in(:,:,2) + 0.5*im_in(:,:,3);
    Cr = 0.5*im_in(:,:,1) -0.419*im_in(:,:,2) - 0.081*im_in(:,:,3);
    CT_image = cat(3, Y, Cb, Cr);
    
end