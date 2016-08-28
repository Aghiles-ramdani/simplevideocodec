function [PSNR_im bit_rate_im] = GOP(pred_method, mydata, numfiles, I, setup)
%Pred_method determines whether the B frames are estimated based on
%forward 1, backward 2 or combination of both predictions 3. 
%Group of picture will be based on IBBPBBPBBPBBP... 
%Will need to have at least 5 P frames to see any significant difference%
%The setup struct contains the following items of interest
%    setup.    n
%              zigzag_cor
%               C
%               s
%               a
%               BinaryTree
%               BinCode      } Three items used for huffman enc of err_img
%               Codelength
%               BinaryTreePos
%               BinCodePos   } Three items used for huffman enc of MVs
%               CodelengthsPos
    
    
    %The first image we always use is the encoded/decoded full image
    im_ref = I;
    %Forward Prediction for B frames
    if(pred_method ==1)
        PSNR_im = zeros(1,numfiles-1);
        bit_rate_im = zeros(1,numfiles-1);
        for j = 2:numfiles
            
            im = mydata{j};
            [PSNR_im(j-1), bit_rate_im(j-1), im_out] = pic_analysis(im, im_ref,setup);
            
            if(mod(j,4)== 0)
               im_ref = im_out; 
            end
        end
    %Backward Prediciton for B Frames    
    elseif(pred_method ==2)
        PSNR_im = zeros(1,(numfiles-mod(numfiles-1,3))-1);
        bit_rate_im = zeros(1,(numfiles-mod(numfiles-1,3))-1);
         for j = 1:3:(numfiles-mod(numfiles-1,3)-1)
             %Perform the anaylsis on the fourth image first and then use
             %this image to predict the previous two images.
            im = mydata{j+3};
            [PSNR_im(j+3-1), bit_rate_im(j+3-1), im_out] = pic_analysis(im, im_ref, setup);
            im_ref = im_out; %This image will also be used for forward prediction
                             %of the next P frame in the next iteration
            %Now perform the Analysis on the the two B frames using the
            %forward frame with Backward prediction
            for k = j+1:j+2
                im = mydata{k};
                 [PSNR_im(k-1), bit_rate_im(k-1), im_out] = pic_analysis(im, im_ref, setup); %always B
            end
         end
    %Implementation of the Forward and backward transform performed on the
    %B frames
    else
        im_ref_f = im_ref;
        PSNR_im = zeros(1,(numfiles-mod(numfiles-1,3))-1);
        bit_rate_im = zeros(1,(numfiles-mod(numfiles-1,3))-1);
        for j = 1:3:(numfiles-mod(numfiles-1,3)-1)
             %Perform the anaylsis on the fourth image first and then use
             %this image to predict the previous two images.
            im = mydata{j+3};
            [PSNR_im(j+3-1), bit_rate_im(j+3-1), im_out] = pic_analysis(im, im_ref_f,setup);
            im_ref_b = im_out; %This image will also be used for forward prediction
                             %of the next P frame in the next iteration
            %Now perform the Analysis on the the two B frames using the
            %forward frame with Backward prediction
            cnt = 1;
            for k = j+1:j+2
                
                im = mydata{k};
                [PSNR_im(k-1), bit_rate_im(k-1)] = pic_analysis_bidirect(im, im_ref_f, im_ref_b,cnt, setup); %always B
                cnt = cnt +1;
            end
            im_ref_f = im_ref_b;
         end
        
    end
end