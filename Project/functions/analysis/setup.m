%Generate Tables Required to Run the main file
close all;
clear all;
clc;

% Provide access to required directories
path(path, 'data/images')
path(path, 'data/tables')
path(path, 'data/video/foreman')
path(path, 'functions/analysis')
path(path, 'functions/encoding')
path(path, 'functions/decoding')
load('zigzag.mat')
% load('table.mat')

% Variable Declaration
dist = 1; % distortion multiple

thenum = 0;
save('thenum.mat', 'thenum');

%Generate DCT Tables
C = cos(pi/16*[1:7]);
s = horzcat([2*sqrt(2)], 4*C).^(-1);
a = [C(4), C(2)-C(6), C(4), C(6)+C(2), C(6)];
save('data/tables/dcttables.mat', 'C', 's', 'a')

% Generate a Huffman Table for Compressing Still Images
im = double(imread('lena_small.tif')); %Calculated for Lena Small Image
CT_image = RGB2YCbCr(im);
enc_lenasmall = IntraEncode(CT_image,dist,zigzag_cor, C, s, a, 0);
PMF = hist(enc_lenasmall(:), (-2000):(2000));
PMF = PMF/(sum(PMF));
[ BinaryTree, HuffCode, BinCode, Codelengths] = buildHuffman( PMF );
save('data/tables/basehuffman.mat','BinaryTree','HuffCode', 'BinCode', 'Codelengths')

% PMF_pos = hist(enc_lenasmall(:), (-4):(4));
% PMF_pos = PMF_pos/(sum(PMF_pos));
% [ BinaryTreePos, HuffCodePos, BinCodePos, CodelengthsPos] = buildHuffman( PMF_pos );
% save('data/tables/huffmanpos.mat', 'BinaryTreePos', 'HuffCodePos', 'BinCodePos', 'CodelengthsPos')

MVavg = [];
for i=0:479
    
    load(sprintf('data/mvdata/mv%d.mat', i));   
    MVavg = [MVavg; MV(:)];    
    
end
PMF_pos = hist(MVavg(:), (-8):(8));
PMF_pos = PMF_pos/(sum(PMF_pos));
[ BinaryTreePos, HuffCodePos, BinCodePos, CodelengthsPos] = buildHuffman( PMF_pos );
save('data/tables/huffmanpos.mat', 'BinaryTreePos', 'HuffCodePos', 'BinCodePos', 'CodelengthsPos')

% Generates a Huffman Table for the error Images based on the saved tables
errim = [];
vectf = reshape([1:5:479;3:5:479],1,[]);
vectb = reshape([2:5:479;4:5:479],1,[]);
for i=0:479
    
    load(sprintf('data/errim/specialhuffman/errim%d.mat', i));
    if( mod(i, 5) == 0 )
        errim = [errim; enc_img(:)];
    elseif any(i==vectf)
        errim = [errim; enc_img_f(:)];
    else
        errim = [errim; enc_img_b(:)];
    end
    
end
PMF_err = hist(errim(:), (-700):(700));
PMF_err = PMF_err/(sum(PMF_err));
[ BinaryTreeErr, HuffCodeErr, BinCodeErr, CodelengthsErr] = buildHuffman( PMF_err );
save('data/tables/huffmanerr.mat', 'BinaryTreeErr', 'HuffCodeErr', 'BinCodeErr', 'CodelengthsErr')

