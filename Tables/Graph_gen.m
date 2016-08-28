%% Create and Save Figures and Data
RDvideoplot = figure;
plot(avg_bit, avg_PSNR, 'DisplayName', 'Original Video Codec Foreman');
hold on
% plot(avg_bit_still, avg_PSNR_still, 'DisplayName', 'Original Still Image Codec');
axis([0 5 28 44])
ylabel('PSNR [dB]')
xlabel('Rate [bit/pixel]')
title('Rate Distortion Plot Video Compression Engine')
% savefig(RDvideoplot,'RDVideoPlotOriglvNew.fig')
% legend('show', 'Location', 'northwest');
