function defaults = raw_aligned_indices(varargin)

%   RAW_ALIGNED_INDICES -- Get default parameter values for ... 
%     make.raw_aligned_indices functions.

defaults = bfw.get_common_make_defaults( varargin{:} );

% Indicates whether to fill un-matched indices that lie between
% successfully matched indices, by duplicating the matched index.
defaults.fill_gaps = true;

% For a given unmatched index, `max_fill` indicates, at maximum, how many
% samples before and after the unmatched index will be searched for a valid
% index. In other words, if no valid index lies within `max_fill` samples 
% of an unmatched index, the unmatched index will remain invalid (0).
defaults.max_fill = 3;

end