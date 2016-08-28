function quant_blk = DeZigZag8x8(zigzag_block, zigzag_cor)

    quant_blk = zigzag_block( zigzag_cor(:) );
    quant_blk = reshape(quant_blk, 8, 8); 

end