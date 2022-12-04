% cleaning stuff
clc;
clear; 
close all;
rng(1111); % random seed

% loaded data from .mat file is a struct 
% fixed parameters (only load the map that is needed)
%=========================Load Data==========================
% load the map
map = load('map2.mat'); 
% assign the parameters
time = map.T; 
colonyPos = map.colony_pos; 
colonyProx = map.colony_proximity_threshold; 
foodProx = map.food_proximity_threshold;
foodSource = map.food_sources; 
mapCoord = map.map_coordinates; 
nAnts = 5; %map.n_ants; 
if length(fieldnames(map)) > 7
    walls = map.walls; % initialize walls
else
    walls = [0 0 0 0]; % initialize wall as empty
end

% customizable parameters (to tune parameters)
speed = 10; % speed of the ants (step size of ants in each time stamp)
rSmell = 5; % size of the radius (to smell pheromones)
sigma1 = 2; % angle update coefficient (with pheromones in r_smell) 
sigma2 = 20; % angle update coefficient (without pheromones in r_smell) 
deltaR = 0.1; % linear decay for red pheromone
deltaB = 0.1; % linear decay for blue pheromon

% initialize the ants
for n = 1:nAnts
    ant = struct; 
    ant.x = colonyPos(1) ; % ant's x position
    ant.y = colonyPos(2); % ant's y position
    ant.angle = 2*pi/nAnts*n; % ant's current angle
    ant.foodStatus = false; % status indicates whethers ants is carrying food
    if n == 1
        ants = ant;
    else
        ants(n) = ant;
    end
end

% initialize pheromones
pheromones1 = []; % x_pos, y_pos For Blue
concentration1 = []; % concentration, indicator 1:blue, 2: red

pheromones2 = []; % For red 
concentration2 = []; 

% colony food counter variable
colonyFood = 0; % counter for the food inside the colony

plotPauseT = 0.01; % time delay between each plot refresh
rsltFig = figure(1); 
for tCurrent = 1:time % iterate over timestamps (i.e., for each timestamp...) 
	clf(rsltFig); 
	xlim([mapCoord(1), mapCoord(3)]); % given the map size
	ylim([mapCoord(2), mapCoord(4)]); 
	%=========================Update Parameters========================
	for i = 1:length(ants) % iterate over ants (i.e., for each ant...) 
		% compute the new angle	
        	if ants(i).foodStatus == false
			[newAngle] = ComputeNewAngle(ants(i).x, ants(i).y, ants(i).angle, pheromones2, concentration2, rSmell, sigma1, sigma2); 
       		else
                	[newAngle] = ComputeNewAngle(ants(i).x, ants(i).y, ants(i).angle, pheromones1, concentration1, rSmell, sigma1, sigma2);
        	end 
		% check movement validity + update ant loction and angle
		[ants(i).x, ants(i).y, ants(i).angle] = MovementValidationExecution(ants(i).x, ants(i).y, newAngle, speed, mapCoord, walls);	
		% if ant is not carrying food, check the food proximity and grab food if it's close to a source.
		if ants(i).foodStatus == false
			[foodSource, indicator] = CheckFoodProximity(ants(i).x, ants(i).y, foodSource, foodProx);
			if indicator == 1
				ants(i).foodStatus = true; 
				ants(i).angle = rem(ants(i).angle + pi, 2*pi); 
			end 
		end
		% else, check the colony proximity and drop the food if it's close.
		[indicator] = CheckColonyProximity(ants(i).x, ants(i).y, colonyPos, colonyProx); 
		% check whether it should drop the food
		if indicator == 1
			if ants(i).foodStatus == true
				% drop the food 
				ants(i).foodStatus = false; 
				colonyFood = colonyFood + 1; 
				ants(i).angle = rem(ants(i).angle + pi, 2*pi); 
			end
			% change ants angle (as long as the ants touch the colony it turn back right away) 
		end
	end % end iterate over ants	
	%========================Update Pheromone===========================
	% decay each diff pheromones and concentration 
	% for the blue pheromones
	if isempty(concentration1) == false	
        	[rows, cols] = size(concentration1); 
		for conInd = 1:rows
            		concentration1(conInd,1) = concentration1(conInd,1) - deltaB;
        	end
    	end
        % for the red pheromones
    	if isempty(concentration2) == false
        	[rows2, cols2] = size(concentration2);
        	for conInd = 1:rows2
            		concentration2(conInd,1) = concentration2(conInd,1) - deltaR; 
       		end
    	end

	% remove the below zero concentration pheromone (blue)
	curInd = 1; 
	while true
		% stopping point
		[curRows, curCols] = size(concentration1); 
		if curInd > curRows || curRows == 0
			break; 
		end
		% delete the below zero pheromone
		if concentration1(curInd,1) <= 0
			concentration1(curInd,:) = []; 
			pheromones1(curInd,:) = []; 
		else 
			% keep looking for the next index
			curInd = curInd + 1; 
		end
	end
	
	% remove the below zero concentration pheromone (red)
    	curInd = 1; 
    	while true
		% stopping point
		[curRows, curCols] = size(concentration2); 
		if curInd > curRows || curRows == 0
			break; 
		end
		% delete the below zero pheromone
		if concentration2(curInd,1) <= 0
			concentration2(curInd,:) = []; 
			pheromones2(curInd,:) = []; 
		else 
			% keep looking for the next index
			curInd = curInd + 1; 
		end
	end
	
	% udpate pheromones and concentration with ants' position
	for antInd = 1:length(ants)
		[rows, cols] = size(pheromones2); 
       		[rows1, cols1] = size(pheromones1);
		if ants(antInd).foodStatus == true
			% drop red pheromone if ant carries food
			curX = ants(antInd).x;
			curY = ants(antInd).y; 
		 	pheromones2(rows+1,:) = [curX curY]; 
			concentration2(rows+1,:) = [1 2];
		else
			% if it's empty, then drop blue pheromone
			curX = ants(antInd).x;
			curY = ants(antInd).y;
		 	pheromones1(rows+1,:) = [curX curY]; 
			concentration1(rows+1,:) = [1 1];
		end	
	end
	%=========================Start Plotting============================
	%******************Plot Colony****************
	viscircles(colonyPos, colonyProx, 'color', 'y'); hold on; 
	%****************Plot Food Sources**********
	plot(foodSource(:,1), foodSource(:,2), 'vm'); hold on; 
	%**************Plot Ants' Position************
	for i = 1:length(ants)
		antsX(i) = ants(i).x; 
		antsY(i) = ants(i).y;
	end
	plot(antsX, antsY, "*k"); hold on; 
	%****************Plot Phermone****************
	if isempty(pheromones) == false
		[rows, cols] = size(pheromones); 	
		for phInd = 1:rows
			curX = pheromones1(phInd,1); 
			curY = pheromones1(phInd,2); 
			con = concentration(phInd,1); 
			if con < 1e-1
				con = 0; 
			end 
			plot(curX, curY, '.', 'Color', [1-con, 1-con, 1], 'MarkerSize', 10); 
		end	
	end
	if isempty(pheromones2) == false
        [rows2, cols2] = size(pheromones2); 	
		for phInd = 1:rows2
			curX = pheromones2(phInd,1); 
			curY = pheromones2(phInd,2); 
			con = concentration2(phInd,1); 
			if con < 1e-1
				con = 0; 
			end 
			plot(curX, curY, '.', 'Color', [1, 1-con, 1-con], 'MarkerSize', 5); 				 			
        	end	
	end
	%***************Plot the Wall*****************
	[nWall, column] = size(walls); 	
	for i=1:nWall
		xS = walls(i,1); % x pos of the start point
		yS = walls(i,2); % y pos of the start point
		w = abs(walls(i,3) - walls(i,1)); % width 
		h = abs(walls(i,4) - walls(i,2)); % height
		rectangle('Position', [xS, yS, w, h], 'FaceColor', 'k', 'EdgeColor', 'k'); 
	end
	pause(plotPauseT); 
end % end iterate over timestamps  	
