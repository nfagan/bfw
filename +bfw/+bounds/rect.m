function in_bounds = rect(x, y, rect)

%   RECT_ROI_IN_BOUNDS -- Return whether coordinates are within a given
%     rect bounds.
%
%     IN:
%       - `x` (double) -- Vector of X coordinates.
%       - `y` (double) -- Vector of Y coordinates. Must match number of x.
%       - `rect` (double) -- Boundaries. 1x4 vector of [min_x, min_y,
%         max_x, max_y] coordinates.
%     OUT:
%       - `in_bounds` (logical)

import shared_utils.assertions.*;

assert__numel( rect, 4, 'the roi bounds' );
assert( numel(x) == numel(y), 'Number of x points must number of y points.' );
assert__is_vector( x );
assert__is_vector( y );

in_x = x >= rect(1) & x <= rect(3);
in_y = y >= rect(2) & y <= rect(4);

in_bounds = in_x & in_y;

end