%Tianling Niu, 7/22/2024
% Code for comparison between manual and automated annotation 

% %% Automated & Manual annotation: ROI extract
% 
% % Read the image
% I1 = imread("73ori.jpg"); I2 = imread("73.jpg");
% % Convert to grayscale 
% grayI1 = rgb2gray(I1);  grayI2 = rgb2gray(I2); 
% % Detect edges using Canny edge detector
% edges1 = edge(grayI1, 'Canny'); edges2 = edge(grayI2, 'Canny');
% % Find contours (connected components)
% contours1 = bwconncomp(edges1); contours2 = bwconncomp(edges2);
% % Assume the largest contour is the annotation area
% numPixels1 = cellfun(@numel, contours1.PixelIdxList);
% [~, idx1] = max(numPixels1);
% mask1 = false(size(grayI1));
% mask1(contours1.PixelIdxList{idx1}) = true;
% 
% numPixels2 = cellfun(@numel, contours2.PixelIdxList);
% [~, idx2] = max(numPixels2);
% mask2 = false(size(grayI2));
% mask2(contours2.PixelIdxList{idx2}) = true;
% % Fill the contour to create a solid mask
%  % mask1 = imfill(mask1, 'holes'); 
% se = strel('disk', 10); mask1 = imclose(mask1,se); mask1 = imfill(mask1, 'holes');
% se = strel('disk', 10); mask2 = imclose(mask2,se); mask2 = imfill(mask2, 'holes');
% 
% se = strel('disk', 10); % You can change numbers for more erosion
% erodedMask1 = imerode(mask1, se); erodedMask2 = imerode(mask2, se);
% mask1 = erodedMask1;  mask2 = erodedMask2;
% 
% % Display the result
% figure(1); imshow(mask1); 
% title('Image Automated');
% figure(2); imshow(mask2);
% title('Image Manual');
% % imwrite(I1,"103auto.jpg");
% % imwrite(I2,"103manu.jpg");
% 
% %%
% img = imread("73wa.jpg");
% red_channel = img(:,:,1);
% green_channel = img(:,:,2);
% blue_channel = img(:,:,3);
% % Adjust the thresholds based on your image
% object_mask = (red_channel > 20 & green_channel > 3 & blue_channel < 100);
% % Convert the logical matrix to a double matrix
% double_ob = double(object_mask);
% % Create the Gaussian filter
% filter_size = 65; % Adjust the filter size as needed
% sigma = 35.0; % Adjust the standard deviation as needed
% gaussian_filter = fspecial('gaussian', filter_size, sigma);
% % Apply the Gaussian filter
% object_mask = imfilter(double_ob, gaussian_filter, 'same');
% % Threshold the smoothed matrix
% threshold = 0.1; % Adjust the threshold as needed
% object_mask = object_mask > threshold; figure(3); imagesc(object_mask);

%% Calculate the scores
% img1 = imread("73ori.jpg");
img1 = img1(:,:,1);
a = find(img1(:,:)>=250);
b = find(img1(:,:)<250);
img1(a) = 255; img1(b) = 0;
img1 = imfill(img1); img1 = logical(img1);
imshow(img1);
% 
% img2 = imread("73.jpg");
% img2 = img2(:,:,1);
% a = find(img2(:,:)>=235);
% b = find(img2(:,:)<235);
% img2(a) = 255; img2(b) = 0;
% img2 = imfill(img2); img2 = logical(img2);
% imshow(img2);
% 
[diceScore jaccardIndex precision recall hd boundaryIoU] = computeScore(img1, img2);
fprintf('Similarity Score:\n Dice Score: %f\n Jaccard Index: %f\n Precision: %f\n Recall: %f\n  haur dis: %f\n boundary:%f\n', ...
    diceScore, jaccardIndex, precision, recall, hd, boundaryIoU);

% [mse deepS] = compute_easysimilarity(img1, img2);
% fprintf('Similarity Reference: \n Mean squared error: %f\n CNN feature and similarity: %f\n', mse, deepS);

% filename = 'Scores.xlsx';
% newdata = {73,diceScore, jaccardIndex, precision, recall, difow, hd, bpundaryiou, mse, ssimval, hist_corr, num_matches, ncc_values, coss, deepS, hog};
% [~,~,raw] = xlsread("Scores.xlsx");
% lastRow = size(raw,1) + 1;
% 
% writecell(newdata,filename,'Sheet',1,'Range',sprintf('A%d',lastRow));