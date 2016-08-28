function blk = IDCT8x8(DCT_blk, C, s, a)

    %Use the fast idct algorithm
    blk = fastidct(fastidct(DCT_blk, C, s, a)', C, s, a);
    %Use Matlabs idct algorithm (uses fourier)
%     blk = idct2(DCT_blk);

end