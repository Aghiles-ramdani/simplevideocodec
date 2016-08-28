%Returns the decoded image without resturning to RGB
function [dec, bytestream] = stillimage(im_ref, dist, zigzag_cor, C, s, a, BinaryTree, BinCode, Codelengths)

    % Encode Process
%     im_ref = mydata{1}; % im_ref = cell2mat(mydata(1));
    CT_image_ref = RGB2YCbCr(im_ref);
    enc_img = IntraEncode(CT_image_ref,dist,zigzag_cor, C, s, a, 0);
    bytestream = enc_huffman_new( round(enc_img(:) + (700) + 1), BinCode, Codelengths);

    % Decode Process
    [width, height, ~] = size(CT_image_ref);
    im_huffdec = dec_huffman_new( bytestream, BinaryTree, size(enc_img(:),1)) -1 -(700);
    dec = IntraDecode(im_huffdec, width, height, dist, zigzag_cor, C, s, a, 0);

end