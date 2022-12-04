function [food_sources, indicator] = CheckFoodProximity(x, y, food_sources, food_proximity_threshold)
%{

functionality:
    compute the distance between the ant location and all food sources.
    find the nearest food source.
    if the distance is less than a threshold, remove that source from the
    foods list, and return 1. else, return 0.

outputs:
    food_sources: the (probably) modified list of food sources.
    indicator: 1, if the ant is near a food source, and 0 else.

inputs:
    x: the x of ant
    y: the y of ant
    food_sources: the list of food sources
    food_proximity_threshold: the threshold to determine proximity

%}

% your code here...
	% loop through all the food find the closest
	% Initialize the parameters
	minInd = -1; 
	minDist = Inf; 
	indicator = 0; 
	[rows, cols] = size(food_sources); 
	for foodInd = 1:rows
		% calculate the distance
		foodX = food_sources(foodInd,1); 
		foodY = food_sources(foodInd,2); 
		dist = ((foodX-x)*(foodX-x) + (foodY-y)*(foodY-y))^0.5; 
		% update the closest food point
		if dist <= food_proximity_threshold
			% food is inside the grab range
			if dist <= minDist
				minDist = dist; 
				minInd = foodInd; 		
			end
		end
	end	
	if minInd ~= -1
		indicator = 1; % grabbed the closest food	
		% remove the food source
		food_sources(foodInd, :) = []; 
	end
end
