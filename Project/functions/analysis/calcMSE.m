function MSE = calcMSE(im1, im2)
    MSE= (1/(size(im1,1)*size(im1,2)*size(im1,3))) * sum(sum(sum((im1-im2).^2)));
end