function [x_new, y_new, angle] = MovementValidationExecution(x, y, angle, speed, allowed, forbidden)
%{

functionality:
    - compute the new ant position.
    - if the new position is valid, return the new position. else, keep the
    current position, and only change the angle by 180 degrees.

outputs:
    x_new: new x of ant
    y_new: new y of ant
    angle: new angle of ant

inputs:
    x: the x of ant
    y: the y of ant
    angle: ant current angle
    speed: ant speed
    allowed: a matrix of N rows and 4 columns, containing lower left and 
        upper right points of the map
    forbidden: a matrix of N rows and 4 columns, containing lower left and 
        upper right points of the walls (boundary of the map)

%}

% your code here...
	% initialize the parameters
	x_new = x; 
	y_new = y; 
	% calculate the next positiion
	if angle == 0 or pi 
		% sin() can't be applied here
		nextX = x + cos(angle)*speed; % only move on x direction	
	elseif angle == pi/2 || angle == 3*pi/2
		% cos() can't be applies here
		nextY = y + sin(angle)*speed; 
	else
		% rest of the angle
		nextX = x + cos(angle)*speed; 
		nextY = y + sin(angle)*speed; 
	end
	% check whether it is inside the map
	xLowLim = allowed(1); xUppLim = allowed(3); 
	yLowLim = allowed(2); yUppLim = allowed(4); 
	if nextX <= xLowLim || nextX >= xUppLim
		angle = rem(angle+pi, 2*pi); % turn the oppsite way
		return; 
	elseif nextY <= yLowLim || nextY >= yUppLim
		angle = rem(angle+pi, 2*pi); % turn the oppsite way
		return; 
	end	
	% check whether it will encounter the wall
	% loop through all the wall, and check whether the ant will it it	
	[rows, cols] = size(forbidden); 
	for wallInd = 1:rows
		xLowLim = forbidden(wallInd,1); 
 		xUppLim = forbidden(wallInd,3); 
		yLowLim = forbidden(wallInd,2); 
 		yUppLim = forbidden(wallInd,4); 
		if nextX >= xLowLim && nextX <=xUppLim
			if nextY >= yLowLim && nextY <= yUppLim
				disp("Hit the wall"); 
				return; 
			end
		end
	end	
	%==================Pass above criteria===============
	% update the return values
	x_new = nextX; 
	y_new = nextY; 
end







