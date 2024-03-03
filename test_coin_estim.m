close all
clearvars 
clc
% Loading images and calculating mean bias, flat and dark images

Bias_fold = dir(fullfile("DIIP-images\Bias", "*.JPG"));
Dark_fold = dir(fullfile("DIIP-images\Dark", "*.JPG"));
Flat_fold = dir(fullfile("DIIP-images\Flat", "*.JPG"));

Bias_filepath = fullfile(Bias_fold(1).folder, Bias_fold(1).name);
dims = size(imread(Bias_filepath));

biases = zeros([dims,5]);
flat = zeros([dims,5]);
darks = zeros([dims,5]);

for index = 1:numel(Bias_fold)
    Bias_filepath = fullfile(Bias_fold(index).folder, Bias_fold(index).name);
    biases(:,:,:,index) = imread(Bias_filepath);

    Dark_filepath = fullfile(Dark_fold(index).folder, Dark_fold(index).name);
    darks(:,:,:,index) = imread(Dark_filepath);

    Flat_filepath = fullfile(Flat_fold(index).folder, Flat_fold(index).name);
    flat(:,:,:,index) = imread(Flat_filepath);
end
mean_bias = mean(biases, 4);
mean_flat = mean(flat, 4);
mean_darks = mean(darks, 4);

% % Demonstrate the pixels which are used in geometric calibration
% demo_flat = mean_flat;
% demo_flat(500:505,:,2) = 255;
% demo_flat(:,end-505:end-500,2) = 255;
% Row = mean(flat(500,:,:),3) < 100; % find all dark pixels in the row
% Col = mean(flat(:,end-500,:),3) < 100; % find all dark pixels in the column
% 
% demo_flat(Col,end-505:end-500,:) = 255;
% demo_flat(500:505,Row,:) = 255; 
% figure
% imshow(uint8(demo_flat))
% title("Geometric calibration lines")
%%
close all
Meas_fold = dir(fullfile("DIIP-images\Measurements", "*.JPG"));
counts = [1, 1, 1, 1, 1, 1;
            3, 1, 0, 1, 0, 0;
            1, 0, 0, 5, 1, 1;
            0, 0, 0, 3, 1, 3;
            0, 1, 0, 4, 1, 3;
            0, 3, 0, 1, 0, 2;
            0, 1, 0, 3, 0, 0;
            0, 0, 1, 4, 0, 3;
            0, 0, 0, 0, 1, 3;
            0, 0, 1, 4, 0, 0;
            0, 3, 1, 5, 0, 0;
            0, 3, 1, 1, 0, 0];

coins = zeros(1,6);
corr = 0;
for index = 1:numel(Meas_fold)
    Meas_filepath = fullfile(Meas_fold(index).folder, Meas_fold(index).name);
    R = imread(Meas_filepath);
    fprintf("\n----------------------------------------------------------------\n");
    fprintf("Image: %d\n", index);
    coins = estim_coins(R, mean_bias, mean_darks, mean_flat);
    fprintf("True # of coins: %d | Found # of coins: %d.\n", sum(counts(index,:)), sum(coins))
    fprintf("# of correctly labeled coins: %d.\n", sum(counts(index,:)) - sum(max(counts(index,:) - coins,0)))
    corr = corr + sum(counts(index,:)) - sum(max(counts(index,:) - coins,0));
end
acc = corr/sum(counts(:));
fprintf("Accuracy: %.2f\n%", acc*100);
