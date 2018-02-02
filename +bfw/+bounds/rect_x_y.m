function ib = rect_x_y( xy, mins, maxs )

%   RECT_X_Y -- Takes x or y components of a rect and returns whether a 
%     vector of samples are within the min and max.
%
%     IN:
%       - `xy` (double) |VECTOR|
%       - `rect` (double) -- 2 element [min, max]

import shared_utils.assertions.*;

assert__is_vector( xy );
assert__is_scalar( mins );
assert__is_scalar( maxs );

ib = xy >= mins & xy <= maxs;

end