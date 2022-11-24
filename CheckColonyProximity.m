function [indicator] = CheckColonyProximity(x, y, colony_pos, colony_proximity_threshold)
%{

functionality:
    compute the distance between the ant location and the colony. If the
    distance is less than a threshold, ant is near colony and therefore
    drops food if it carries it.

outputs:
    indicator: 1, if the ant is near colony, and 0 else.

inputs:
    x: the x of ant
    y: the y of ant
    colon_pos: colony position
    colony_proximity_threshold: the threshold to determine proximity

%}

% your code here...
	%intialize the parameters
	indicator = false; 
	% compute the distance
	colonyX = colony_pos(1); 
	colonyY = colony_pos(2); 
	dist = ((colonyX-x)*(colonyX-x) + (colonyY-y)*(colonyY-y))^0.5;
	if dist <= colony_proximity_threshold
		indicator = true; 
	end
end
