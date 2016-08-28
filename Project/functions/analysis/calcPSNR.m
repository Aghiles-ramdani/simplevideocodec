function PSNR = calcPSNR(im1, im2)
    mse = calcMSE(im1, im2);
    PSNR = 10*log10(1/mse);
end