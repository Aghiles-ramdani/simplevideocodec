function [PSNR, bit_rate, im_out] = pic_analysis(im, im_ref,setup)
    srch_rang = 4;
    huff_add = 700;
    %% Encoding Process
    % Convert form RGB to YCbCr format
    CT_image = RGB2YCbCr(im);
    % Perform motion estimation based on image reference
    [err_im, MV] = motionEstimation(im_ref, CT_image);
    % Encode image with the intraecnoder (Still image codec)
    enc_img = IntraEncode(err_im,setup.n,setup.zigzag_cor, setup.C, setup.s, setup.a, 0);
    % Saving encoded data so that Huffman Tables can be generated
    % accordingly
% % %     load('thenum.mat')
% % %     save(sprintf('data/errim/errim%d.mat', thenum), 'enc_img');
% % %     thenum = thenum + 1;
% % %     save('thenum.mat', 'thenum');   
    % Huffman encode the motion vectors
    bytestream2 = enc_huffman_new( 2*(MV(:)+ srch_rang) + 1 ,setup.BinCodePos, setup.CodelengthsPos);
    % Huffman encode the error image
    bytestream1 = enc_huffman_new( round(enc_img(:) + (huff_add) + 1), setup.BinCode, setup.Codelengths);

    %% Decoding Process
    %Decode the error images first
    width = size(CT_image,1);
    height = size(CT_image,2);
    im_huffdec = dec_huffman_new( bytestream1, setup.BinaryTree, size(enc_img(:),1)) -1 -(huff_add);
    im_err = IntraDecode(im_huffdec, width, height, setup.n, setup.zigzag_cor, setup.C, setup.s, setup.a, 0);
    %Decide the motion vectors
    MV_huffdec = ((dec_huffman_new( bytestream2, setup.BinaryTreePos, size(MV(:),1)) -1 )/2)-srch_rang;
    %reconstruct out image from the error image and the motion vectors
    dec = motion_compensation(im_ref, im_err, MV_huffdec);
    im_out = dec;
    %Convert back to RGB format
    rec_image = YCbCr2RGB(dec);
    %Calculate the PSNR with respect to the original image
    PSNR = calcPSNR(im/256, rec_image/256);
    bit_rate = ((((size(bytestream2,1)+size(bytestream1,1))*8)/(size(rec_image,1)*size(rec_image,2))));
end