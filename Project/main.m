%--------------------------------------------------------------
%
%
% main program for Hybrid Video Codec
%    Program performs compression/decompression and generates
%    a distortion graph 
%
%
% input:       none
%
% Course:      Image and Video Compression
%              Prof. Eckehard Steinbach
%
% Author:      Nathan Gibbs
%              Edward Wall
%
%
%---------------------------------------------------------------

%% Reset Environment
close all
clear all
clc

%% Provide access to required directories
path(path, 'data/images')
path(path, 'data/tables')
path(path, 'data/video/foreman')
path(path, 'functions/analysis')
path(path, 'functions/encoding')
path(path, 'functions/decoding')

%% load in required data
load('zigzag.mat')
load('basehuffman.mat')
load('dcttables.mat')
load('huffmanpos.mat')
load('huffmanerr.mat')

%% Load in Video File for Analysis
dist = 1; % distortion multiple
numfiles = 21; % number of files in video sequence
mydata = cell(1, numfiles);
for k = 1:numfiles
  myfilename = sprintf('foreman00%d.bmp', k+19);
  mydata{k} = double(imread(myfilename));
end

%% Run Video Codec through a range of distortion values
iter_cnt = 1; %iterator for position in dist_range
dist_range = .1:0.25:4; %scale factor for distortion
% Averages across the sequence for a given distortion value
avg_PSNR = zeros(1,length(dist_range));
avg_bit = zeros(1,length(dist_range));
%Variables for measuing PSNR and Bit Rate so data can be analysed
PSNR_im = zeros(1,numfiles);
bit_rate_im = zeros(1,numfiles);
t = 50; % Approximate time per distortion
for n = dist_range
    fprintf('Calculating distortion %.2f  (%i of %i) ~%.1fs remaining\n', n, iter_cnt, length(dist_range), t*(length(dist_range)-iter_cnt+1))
    tic;    
    
    %% Perform Still Image Encode on first image
    im_ref = mydata{1};
    [dec, bytestream] = stillimage(im_ref, n, zigzag_cor, C, s, a, BinaryTree, BinCode, Codelengths);
    rec_im = YCbCr2RGB(dec);
    
    % Calculate the PSNR with respect to the original image
    PSNR_im = calcPSNR(im_ref/256, rec_im/256);
    bit_rate_im = (((size(bytestream,1)*8)/(size(rec_im,1)*size(rec_im,2))));
 
    %Create the setup structure
    setup.n= n;
    setup.zigzag_cor = zigzag_cor;
    setup.C = C;
    setup.s = s;
    setup.a = a;
    setup.BinaryTree = BinaryTreeErr;
    setup.BinCode = BinCodeErr;     
    setup.Codelengths = CodelengthsErr;
    setup.BinaryTreePos = BinaryTreePos;
    setup.BinCodePos = BinCodePos;
    setup.CodelengthsPos = CodelengthsPos;
    
    [PSNR_im_GOP, bit_rate_im_GOP] = GOP(3, mydata, numfiles, dec, setup);
    PSNR_im = [PSNR_im PSNR_im_GOP];
    bit_rate_im = [bit_rate_im bit_rate_im_GOP];

    avg_PSNR(iter_cnt) = mean(PSNR_im(1:end));
    avg_bit(iter_cnt) = mean(bit_rate_im(1:end));
    iter_cnt = iter_cnt +1;
    t = (toc+(t*(iter_cnt-1)))/iter_cnt;
end

%% Create and Save Figures and Data
RDvideoplot = figure;
plot(avg_bit, avg_PSNR);
axis([0 3.6 28 43])
ylabel('PSNR [dB]')
xlabel('Rate [bit/pixel]')
title('Rate Distortion Plot Video Compression Engine')
savefig(RDvideoplot,'data/results/RDVideoPlot.fig')
save('data/results/RDvideo.mat', 'avg_bit', 'avg_PSNR')
clc;
fprintf('Complete. Data saved to data/results/\n')