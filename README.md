# DIIP-Project-work
Project work for the course Digital imaging and Image preprocessing


estim_coins.m contains the coin count estimation task. It takes a measurement image, a mean bias,
a mean dark and a mean flat image as its inputs and outputs a vector containing the counts of each
coin type in the following order: [2e,1e,50cnt,20cnt,10cnt,5cnt]. The test_estim_coins.m contains a
routine for testing the coin estimation function with all relevant images in a "DIIP-images"-folder
and different types of images are in their own subfolders (for example "DIIP-images/Bias/*.JPG").
DIIP_PA.pdf contains a comprehensive report of the estimation routine and achieved results.
