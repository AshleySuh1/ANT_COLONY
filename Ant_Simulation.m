% cleaning stuff
clc;
clear; 
close all;
rng(1111); % random seed

% loaded data from .mat file is a struct 
mapName = "map2"; % choosing the map to access the parameters
% fixed parameters (only load the map that is needed)
%=========================Load Data==========================
switch mapName
	case "map1"	
		% load the map
		map1 = load('map/map1.mat'); 
		% assign the parameters
		time = map1.T; 
		colonyPos = map1.colony_pos; 
		colonyProx = map1.colony_proximity_threshold; 
		foodProx = map1.food_proximity_threshold;
		foodSource = map1.food_sources; 
		mapCoord = map1.map_coordinates; 
		nAnts = map1.n_ants; 
		walls = [0 0 0 0]; % initialize wall as empty
	case "map2" 
		% load the map
		map2 = load('map/map2.mat'); 
		% assign the parameters
		time = map2.T; 
		colonyPos = map2.colony_pos; 
		colonyProx = map2.colony_proximity_threshold; 
		foodProx = map2.food_proximity_threshold;
		foodSource = map2.food_sources; 
		mapCoord = map2.map_coordinates; 
		nAnts = map2.n_ants; 
		walls = [0 0 0 0]; % initialize wall as empty
	case "mapWall"
		% load the map
		mapWall = load("map/map3_ExtraCredit.mat"); 
		% assign the parameters
		time = mapWall.T; 
		colonyPos = mapWall.colony_pos; 
		colonyProx = mapWall.colony_proximity_threshold; 
		foodProx = mapWall.food_proximity_threshold;
		foodSource = mapWall.food_sources; 
		mapCoord = mapWall.map_coordinates; 
		nAnts = mapWall.n_ants; 
		walls = mapWall.walls;
	otherwise
		error("Name of the map is wrond"); 
end

% customizable parameters (to tune parameters)
speed = 10; % speed of the ants (step size of ants in each time stamp)
rSmell = 5; % size of the radius (to smell pheromones)
sigma1 = 20; % angle update coefficient (with food in r_smell) 
sigma2 = 2; % angle update coefficient (without food in r_smell) 
deltaR = 0.1; % linear decay for red pheromone
deltaB = 0.1; % linear decay for blue pheromon

% initialize the ants
% create the ant struct
ant = struct; 
ant.x = colonyPos(1) ; % ant's x position
ant.y = colonyPos(2); % ant's y position
ant.angle = 0; % ant's current angle
ant.foodStatus = false; % status indicates whethers ants is carrying food
ants = repmat(ant, 1, nAnts);% create the ants with array of struct 

% initialize pheromones
pheromones = []; % x_pos, y_pos
concentration = []; % concentration, indicator 1:blue, 2: red

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
		[newAngle] = ComputeNewAngle(ants(i).x, ants(i).y, ants(i).angle, pheromones, concentration, rSmell, sigma1, sigma2); 
		% check movement validity + update ant loction and angle
		[ants(i).x, ants(i).y, ants(i).angle] = MovementValidationExecution(ants(i).x, ants(i).y, newAngle, speed, mapCoord, walls);	
		% if ant is not carrying food, check the food proximity and grab food if it's close to a source.
		if ants(i).foodStatus == false
			[foodSource, indicator] = CheckFoodProximity(ants(i).x, ants(i).y, foodSource, foodProx);
			if indicator == true
				ants(i).foodStatus = true; 
				ants(i).angle = rem(ants(i).angle + pi, 2*pi); 
			end 
		end
		% else, check the colony proximity and drop the food if it's close.
		[indicator] = CheckColonyProximity(ants(i).x, ants(i).y, colonyPos, colonyProx); 
		% check whether it should drop the food
		if indicator == true
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
	if isempty(concentration) == false
		[rows, cols] = size(concentration); 
		for conInd = 1:rows
			if concentration(conInd,2) == 1 % if it's a blue pheromone
				concentration(conInd,1) = concentration(conInd,1) - deltaB; 
			elseif concentration(conInd, 2) == 2 % if it's a red pheromone
				concentration(conInd,1) = concentration(conInd,1) - deltaR; 
			end
		end
		% remove the below zero concentration pheromone 
		curInd = 1; 
		while true
			% stopping point
			[curRows, curCols] = size(concentration); 
			if curInd > curRows || curRows == 0
				break; 
			end
			% delete the below zero pheromone
			if concentration(curInd,1) <= 0
				concentration(curInd,:) = []; 
				pheromones(curInd,:) = []; 
			else 
				% keep looking for the next index
				curInd = curInd + 1; 
			end
		end
	end
	% udpate pheromones and concentration with ants' position
	for antInd = 1:length(ants)
		[rows, cols] = size(pheromones); 
		if ants(antInd).foodStatus == true
			% drop red pheromone if ant carries food
			curX = ants(antInd).x;
			curY = ants(antInd).y; 
		 	pheromones(rows+1,:) = [curX curY]; 
			concentration(rows+1,:) = [1 2];
		else
			% if it's empty, then drop blue pheromone
			curX = ants(antInd).x;
			curY = ants(antInd).y;
		 	pheromones(rows+1,:) = [curX curY]; 
			concentration(rows+1,:) = [1 1];
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
			curX = pheromones(phInd,1); 
			curY = pheromones(phInd,2); 
			con = concentration(phInd,1); 
			if con < 1e-1
				con = 0; 
			end 
			type = concentration(phInd,2); 
			if type == 1 % blue pheromone
				plot(curX, curY, '.', 'Color', [1-con, 1-con, 1], 'MarkerSize', 10); 
			else 
				plot(curX, curY, '.', 'Color', [1, 1-con, 1-con], 'MarkerSize', 10); 
			end
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
