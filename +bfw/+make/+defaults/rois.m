function defaults = rois(varargin)

%   ROIS -- Get default parameter values for ... make.rois function.

defaults = bfw.get_common_make_defaults( varargin{:} );

% 'rois' gives the name(s) of the roi(s) to be processed. It can be a cell
% array of strings or a char vector. If the value is the char vector 'all'
% (the default), then all rois are processed; otherwise, an error is thrown
% if the specified roi does not exist.
defaults.rois = 'all';

end