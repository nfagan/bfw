function [out, min_v, max_v] = norm01(vec, min_maxs)

%   NORM01 -- Normalize data to [0, 1] interval.
%
%     normed = bfw.norm01( data ) transforms the double or single vector
%     `data` such that its values are within the range [0, 1], inclusive.
%     The normalization is based on the minimum and maximum elements of
%     `data`.
%
%     [..., min_v, max_v] also returns the minimum and maximum value of
%     `data`.
%
%     bfw.norm01( ..., min_maxs ) for the 2-element double or single vector
%     `min_maxs` uses the minimum and maximum from this vector, instead of
%     calculating it from `data`. The minimum is the first element.
%
%     See also bfw.norm_rect

validateattributes( vec, {'double', 'single'}, {'vector'}, mfilename, 'vec' );

if ( nargin < 2 )
  min_v = min( vec );
  max_v = max( vec );
else
  validateattributes( min_maxs, {'double', 'single'}, {'vector', 'numel', 2} ...
    , mfilename, 'min_maxs' );
  assert( min_maxs(2) >= min_maxs(1), 'Max must follow min.' );
  
  min_v = min_maxs(1);
  max_v = min_maxs(2);
end

span = max_v - min_v;
out = (vec - min_v) / span;

end