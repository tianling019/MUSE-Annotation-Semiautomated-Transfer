% Tianling Niu; 5/13/2024; final accomplishment: 7/29/2024
% compare the two images in one plot
% https://www.mathworks.com/help/images/example-performing-image-registration.html

clear all;
close all; clc;
moving = imread("73_forH&E.jpg"); %movingImg = imcomplement(movingImg);
fixed = imread("73no.jpg"); %imread("92_1.jpg");
%imshow(moving);

%% other registration methods trying
% Resize moving image to match fixed image size
moving = imresize(moving, [size(fixed,1), size(fixed,2)]);
[optimizer,metric] = imregconfig("multimodal");
reg_r = imregister(moving(:,:,1),fixed(:,:,1),"affine",optimizer,metric);imshow(reg_r);
reg_g = imregister(moving(:,:,2),fixed(:,:,2),"affine",optimizer,metric);
reg_b = imregister(moving(:,:,3),fixed(:,:,3),"affine",optimizer,metric);
% Recombine channels
reg = cat(3, reg_r, reg_g, reg_b);

% Convert to uint8 if needed (imregister often returns double)
if ~isa(reg, 'uint8')
    reg = im2uint8(reg);  
end

% Display final registered image
imshow(reg); registered1 = reg;
title('Registered RGB Image');
%% Select paired points from MUSE images and H&E images
cpselect(moving, fixed);

%% Image registration on MUSE images
tform = fitgeotform2d(movingPoints,fixedPoints,"polynomial",2);
% registered = imwarp(moving,tform,FillValues=255);
Rfixed = imref2d(size(fixed));
registered1 = imwarp(moving,tform,FillValues=255,OutputView=Rfixed);
% remove the deformed background
for i = 1:size(registered1,1)
    for j = 1:size(registered1,2)
        if registered1(i,j,:) == 255 
            registered1(i,j,:) = 0;
        end
        if registered1(i,j,:) == 0
            registered1(i,j,:) = 1;
        end
    end
end

imshow(registered1); %imagesc(registered1);
% imwrite(registered1, "73wa.jpg"); 

%% Annotation outline extraction from H&E images
HEw = imread("73.jpg");
HE = imread("73no.jpg");
outline1 = rgb2gray(HE-HEw);
imagesc(outline1); colormap gray;
%figure; imshowpair(registered1,outline1,"blend");
for i = 1:size(outline1,1)
    for j = 1:size(outline1,2)
        if outline1(i,j) > 40
            outline1(i,j) = 255;
        end
        if outline1(i,j) ~= 255
            outline1(i,j) = 1;
        end
    end
end

zero = find(registered1(:)==0); registered1(zero) = 1;
figure; imagesc(outline1); colormap gray;
mul = (outline1.*registered1);
figure; imagesc((mul));

%% Annotation refine: adjust the outline to tissue edges
img = mul;
gray_img = rgb2gray(img);
annotation_mask = img(:,:,1) > 200 & img(:,:,2) > 200 & img(:,:,3) > 200;
annotation_mask = imfill(annotation_mask, 'holes'); %figure(1); imagesc(annotation_mask);
red_channel = img(:,:,1);
green_channel = img(:,:,2);
blue_channel = img(:,:,3);
% Adjust the thresholds based on your image
object_mask = (red_channel > 20 & green_channel > 5 & blue_channel < 100);
% Convert the logical matrix to a double matrix
double_ob = double(object_mask);
% Create the Gaussian filter
filter_size = 59; % Adjust the filter size as needed
sigma = 15.0; % Adjust the standard deviation as needed
gaussian_filter = fspecial('gaussian', filter_size, sigma);
% Apply the Gaussian filter
object_mask = imfilter(double_ob, gaussian_filter, 'same');
% Threshold the smoothed matrix
threshold = 0.1; % Adjust the threshold as needed
object_mask = object_mask > threshold; %figure(2); imagesc(object_mask);
final_mask = annotation_mask & object_mask; %figure(3); imagesc(final_mask);
% Define the structuring element with the desired thickness
se = strel('disk', 5); % Half the thickness (7 pixels / 2 ≈ 3 pixels)
% Erode the logical matrix to get the inner boundary
eroded_mask = imerode(final_mask, se);
% Subtract the eroded matrix from the original matrix to get the annotation line
annotation_line = final_mask & ~eroded_mask; %figure(4); imagesc(annotation_line);
annotation_line = uint8(~annotation_line); imagesc(annotation_line);
f = find(annotation_line==0); annotation_line(f) = 255;
aMUSE = annotation_line .* registered1; imagesc(aMUSE);
%imwrite(aMUSE,"73a.jpg");


%% resize the image to get the outline
% fixed = imread("73.jpg");
% fixed = imcrop(fixed,[720,0,2009,1920]);
% figure;imagesc(fixed);
% imwrite(fixed,"73.jpg");
% afixed = imread("73no.jpg");
% afixed = imcrop(afixed,[720,0,2009,1920]);
% imwrite(afixed,"73no.jpg");

%%
MUSE = imread('73.jpg');
% moving = imresize(MUSE,[8741,8045]);
load('tform'); 
Rfixed = imref2d(size(fixed));
registered = imwarp(MUSE,tform,FillValues=255,OutputView=Rfixed); 
for i = 1:size(registered,1)
    for j = 1:size(registered,2)
        if registered(i,j,:) == 255 
            registered(i,j,:) = 0;
        end
        if registered(i,j,:) == 0
            registered(i,j,:) = 1;
        end
    end
end
registered(1:7,420:1080,:) = 255;registered(700:930,1:7,:) = 255;

imagesc(registered);
% imwrite(registered,"73manu.jpg");


%% deform back the annotation and apply to the original MUSE
load tform.mat; load fixedPoints.mat; load movingPoints.mat;
R = imref2d(size(moving));
tformInv = fitgeotform2d(fixedPoints,movingPoints,"polynomial",2);
deformed = imwarp(annotation_line,tformInv,FillValues=255,OutputView=R);
deformed(1:600,:)=0; deformed(:,1:100)=0; deformed(500:3080,50:450)=0;
deformed(550:1050, 400:1600)=0; deformed(550:850, 1500:2100)=0; deformed(580:650,2000:2800)=0;
deformed(645:660,2094:2740)=0; deformed(650:678,2090:2415)=0; deformed(670:720,2097:2313)=0;

deformed(3935:5725,8020:8045)=255;
re = find(deformed(:,:)==0);
deformed(re)=1;
imshow(deformed);
re = find(moving(:,:,:)==0);
moving(re) = 1;
ori = deformed .* moving;
imshow(ori);

imwrite(ori,"73ori.jpg");
