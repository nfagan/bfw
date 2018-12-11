function defaults = raw_bounds(varargin)

%   RAW_BOUNDS -- Get default parameter values for ... make.raw_bounds
%     function.

defaults = bfw.get_common_make_defaults();

% Padding gives the number of *pixels* to be applied to an roi's x and y
% dimensions, expanding it. It can be negative to reduce the size of an
% roi.
%
% If the value of this parameter is a scalar number, it will be applied to
% *all* active rois. If this parameter is instead a containers.Map or
% struct, then only the active roi names that have a corresponding entry in
% the padding object will have padding applied to them, and the padding
% amount is specific to each given roi.
defaults.padding = 0;

end