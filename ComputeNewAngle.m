function [angle] = ComputeNewAngle(x, y, ant_angle, pheromones, concentration, r_smell, sigma_1, sigma_2)
%{

functionality:
    - if there are no pheromones in the map, the angle only changes in a 
    random way controlled by the normal distribution specified in the 
    project description. Then, terminate the function.
    - compute the pheromones positions relative to x,y, and also their
    distance.
    - compute the pheromones angles relative to the x axis in range 0, 2pi.
    - filter out the unavailable pheromones.
    - if there are no available pheromones in the map, the angle only 
    changes in a random way controlled by the normal distribution specified
    in the project description. Then, terminate the function.
    - compute the mean of value of all the pheromones positions weighted by
    their concentration.
    - compute the new angle.

outputs:
    angle: the new angle of the ant

inputs:
    x: the x of ant
    y: the y of ant
    ant_angle: the current angle of ant
    pheromones: list of all pheromones
    concentration: list of all pheromone concentrations
    r_smell: the distance in which ant can smell pheromones
    sigma_1: the angle randomness sigma, if ant finds pheromones
    sigma_2: the angle randomness sigma, if ant does not find pheromones
%}

% Loop through all the pheromones
	%	1. Check the distance is <= radius
	% 2. Check the relative angle is between [-90, 90]
	% 3. Update the Maximum, and it's index 
% Update ant's angle with maximum + noise
	angle = ant_angle; 
	[rows, cols] = size(pheromones); 
	% loop through all the pheromones
	dist = 0; relativeAngle = 0; 
	maxPh = 0; maxInd = -1; 
	for phInd = 1:rows
		% check the angle
		phX = pheromones(phInd,1); % get current pheromone x,y position
		phY = pheromones(phInd,2); 
		relativeAngle = atan2(phY-y, phX-x); 
		if abs(ant_angle - relativeAngle) > pi/2
			% a ant can't smell things in this angle
			continue; 
		end
		% check the distance
		dist = ((phX-x)*(phX-x) + (phY-y)*(phY-y))^0.5; 
		if dist > r_smell % is further than a ant can smell
			continue; 
		end
		%==================Pass the smell criteria==================
		% update the max phermone point and it's index	
		if concentration(phInd,1) >= maxPh
			% update the value of the strongest pheromone
			maxPh = concentration(phInd,1); 
			% update the max index
			maxInd = phInd;
		end
	end
	%==============Start update the ant's angle==============
	if maxInd ~= -1 % if the ant smelled pheromones 	
		angle =  relativeAngle + normpdf(rand(), 0, sigma_1); 
	else % if there is not pheromone in the smell area
		angle = ant_angle + normpdf(rand(), 0, sigma_2); 
	end
	% keep the angle under 360 degree
	angle = rem(angle, 2*pi); 
end
