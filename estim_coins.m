function [coins] = estim_coins(measurement, bias, dark, flat)
    % [coins] = estim_coins(measurement, bias, dark, flat) returns the
    % estimated amounts of coins in the image "measurement" as a vector
    % where the order of coins is [2e,1e,50cnt,20cnt,10cnt,5cnt]. 
    % The "bias","dark" and "flat" images are the means of each image type. 
    % This method uses a four step approach to segmentation and labelling of the
    % coins in an given measurement image. Before this, the method
    % calibrates the given measurement image intensity using the extra
    % images. Given RGB image is then translated into grayscale for the
    % segmentation task. The whole process is visualized with images of
    % each step.
    %
    % The segmentation steps:
    % 1. Binarization
    % 2. Dilation & fill
    % 3. Erosion
    % 4. Circle detection & labelling


    % set the images into double format to make sure that calculations work
    % as they should
    img = double(measurement);
    mean_darks = double(dark);
    mean_bias = double(bias);
    mean_flat = double((flat-mean(flat(:))) ./ std2(flat))+1; % scale the mean flat

    % actual coin diameters in millimeters
    two_euro = 25.75;
    one_euro = 23.25;
    fifty_cent = 24.25;
    twenty_cent = 22.25;
    ten_cent = 19.75;
    five_cent = 21.25;
    
    Coins_in_mm = [two_euro, one_euro, fifty_cent, twenty_cent, ten_cent, five_cent];
    
    % square sidelength in millimeters
    
    d = 12.5;
    
    % Using the 500th row of pixels and the 500th last column of pixels as the
    % approximators of the square pixel sizes to find the conversion rate of mm
    % to px by finding the longest streaks of black pixels. This is not
    % that accurate as the squares in a slight angle.
    
    Row = mean(flat(500,:,:),3) < 100; % find all dark pixels in the row
    Col = mean(flat(:,end-500,:),3) < 100; % find all dark pixels in the column
    

    xd = diff([0 Row 0]);
    sx = find(xd == 1); % start of the streak
    ex = find(xd == -1); % end of the streak
    x = max(ex-sx); % find the maximum streak of 1s
    
    
    yd = diff([0 Col' 0]);
    sy = find(yd == 1); % start of the streak
    ey = find(yd == -1); % end of the streak
    y = max(ey-sy); % find the maximum streak of 1s
    
    % Square size in pixels
    sq = [x,y];
    
    % Find how much one millimeter is in pixels using the mean of the
    % square width and height.
    mm_to_px = d/mean(sq);
    
    % Coin diameters in pixels
    Coins_in_px = Coins_in_mm./mm_to_px;
    
    %mean(mean_flat(:))
    figure
    % Original image
    nexttile
    calibrated = uint8((img-mean_bias-mean_darks)./mean_flat);
    imshow(calibrated)
    title("Calibrated")


    % Calibrate the images to even out the intensity of the image and
    % change rgb to grayscale
    gray = rgb2gray(uint8((img-mean_bias-mean_darks)./mean_flat)); % calibrate and set to grayscale.
    nexttile
    imshow(gray)
    title("Calibrated and grayscaled image")
    

    % Binarize the calibrated image using a threshold found by graythresh.
    % Invert the binarized image to have the blobs be white and background
    % black.
    thresh = graythresh(calibrated);
    binarized = ~imbinarize(gray, thresh);
    nexttile
    imshow(binarized)
    title("Binarized and inverted image")
    
    % Exaggerate the size of the found blobs using a disk shaped dilation and
    % fill the holes in the blobs using imfill. (trying to specify the
    % coins in the images)
    sd = strel('disk', 21);
    Blobs = imfill(imdilate(binarized,sd), 'holes');
    nexttile
    imshow(Blobs)
    title("Dilated and filled blobs")
    
    % Try to smooth out the blobs using imerode and a disk shaped
    % neighbourhood
    se = strel('square', 28);
    eroded = imerode(Blobs,se);
    nexttile
    imshow(eroded)
    title("Eroded blobs")

    % find the circles and their radii using imfindcircles (we can specify the
    % range of radii in pixels by finding the smallest and largest radii in the
    % Coins_in_px vector).
    
    min_rad = floor(min(Coins_in_px/2)-40);
    max_rad = ceil(max(Coins_in_px/2)+40); % divide by two as the values are the diameters of the coins and add some margin to the range
    
    [centers, radii, metric] = imfindcircles(eroded, [min_rad, max_rad], ...
                                    'ObjectPolarity','bright', ...
                                    'Sensitivity', 0.98); 
    % use object polarity bright to find bright circles from the background
    % and tuned the sensitivity a bit to find most if not all of the coins
    
    nexttile
    imshow(uint8(img))
    hold on
    thresh = 0.047; % A metric threshold found by trial and error
    
    strongC = centers(metric>thresh,:); % take only the strongest found circles
    strongR = radii(metric>thresh);
    viscircles(strongC, strongR ,'EdgeColor','g', 'LineWidth', 1); % visualize the found coins
    title("Found coins")


    % Infer the coin types by find the closest size
    coins = zeros(1,6);
    for found_coin = 2*strongR' % turn radii of the found coins into diameter
        D = abs(Coins_in_px-found_coin);
        coins = coins + (D == min(D));
    end
end



