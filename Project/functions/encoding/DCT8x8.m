function DCT_blk = DCT8x8(blk, C, s, a)

    %Use the fast dct algorithm
    DCT_blk = fastdct(fastdct(blk, C, s, a)', C, s, a);
    %Use Matlabs idct algorithm (uses fourier)
%     DCT_blk = dct2(blk);

end