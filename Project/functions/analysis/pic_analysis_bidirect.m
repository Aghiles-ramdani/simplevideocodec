function [PSNR, bit_rate] = pic_analysis_bidirect(im, im_ref_f, im_ref_b, b_frame_no, setup)
    srch_rang = 4;
    huff_add = 700;
    %% Encoding Process
    % Convert form RGB to YCbCr format
    CT_image = RGB2YCbCr(im);
    % Perform motion estimation based on image reference
    [err_im_f, MV_f] = motionEstimation(im_ref_f, CT_image);
    [err_im_b, MV_b] = motionEstimation(im_ref_b, CT_image);
    
    % Encode image with the intraecnoder (Still image codec)
    enc_img_f = IntraEncode(err_im_f,setup.n,setup.zigzag_cor, setup.C, setup.s, setup.a, 0);
    enc_img_b = IntraEncode(err_im_b,setup.n,setup.zigzag_cor, setup.C, setup.s, setup.a, 0);
    % Saving encoded data so that Huffman Tables can be generated
    % accordingly
% % %     load('thenum.mat')
% % %     save(sprintf('data/errim/errim%d.mat', thenum), 'enc_img_f');
% % %     save(sprintf('data/errim/errim%d.mat', thenum+1), 'enc_img_b');
% % %     thenum = thenum + 2;
% % %     save('thenum.mat', 'thenum');    
    % Huffman encode the motion vectors
    bytestream2_f = enc_huffman_new( 2*(MV_f(:)+ srch_rang) + 1, setup.BinCodePos, setup.CodelengthsPos);
    bytestream2_b = enc_huffman_new( 2*(MV_b(:)+ srch_rang) + 1, setup.BinCodePos, setup.CodelengthsPos);
    % Huffman encode the error image
    bytestream1_f = enc_huffman_new( round(enc_img_f(:) + ( huff_add) + 1), setup.BinCode, setup.Codelengths);
    bytestream1_b = enc_huffman_new( round(enc_img_b(:) + ( huff_add) + 1), setup.BinCode, setup.Codelengths);

    %% Decoding Process
    %Decode the error images first
    width = size(CT_image,1);
    height = size(CT_image,2);
    im_huffdec_f = dec_huffman_new( bytestream1_f, setup.BinaryTree, size(enc_img_f(:),1)) -1 -( huff_add);
    im_huffdec_b = dec_huffman_new( bytestream1_b, setup.BinaryTree, size(enc_img_b(:),1)) -1 -( huff_add);
    
    im_err_f = IntraDecode(im_huffdec_f, width, height, setup.n, setup.zigzag_cor, setup.C, setup.s, setup.a, 0);
    im_err_b = IntraDecode(im_huffdec_b, width, height, setup.n, setup.zigzag_cor, setup.C, setup.s, setup.a, 0);
    
    %Decode the motion vectors
    MV_huffdec_f = ((dec_huffman_new( bytestream2_f, setup.BinaryTreePos, size(MV_f(:),1)) -1 )/2)-srch_rang;
    MV_huffdec_b = ((dec_huffman_new( bytestream2_b, setup.BinaryTreePos, size(MV_b(:),1)) -1 )/2)-srch_rang;
    %reconstruct out image from the error image and the motion vectors
    dec_f = motion_compensation(im_ref_f, im_err_f, MV_huffdec_f);
    dec_b = motion_compensation(im_ref_b, im_err_b, MV_huffdec_b);
    if(b_frame_no == 1)
        dec = (2/3)*dec_f + (1/3)*dec_b;
    else
        dec = (1/3)*dec_f + (2/3)*dec_b;
    end
    %Convert back to RGB format
    rec_image = YCbCr2RGB(dec);
    %Calculate the PSNR with respect to the original image
    PSNR = calcPSNR(im/256, rec_image/256);
    bit_rate = ((((size(bytestream2_f,1)+size(bytestream1_f,1)+size(bytestream2_b,1)+size(bytestream1_b,1))*8/2)/(size(rec_image,1)*size(rec_image,2))));

end