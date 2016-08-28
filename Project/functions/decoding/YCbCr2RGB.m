function imageRGB = YCbCr2RGB(imageCONV)

    R = imageCONV(:,:, 1) + 1.402*imageCONV(:,:, 3);
    G = imageCONV(:,:, 1) - 0.344*imageCONV(:,:, 2) -0.714*imageCONV(:,:, 3);
	B = imageCONV(:,:, 1) + 1.772*imageCONV(:,:, 2);
    imageRGB = cat(3,R, G, B);
    
end