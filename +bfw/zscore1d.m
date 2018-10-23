function varargout = zscore1d(x, nanflag)

%   ZSCORE1D -- Get zcore normalized data, across the first dimension.
%
%     z = bfw.zscore1d( X ) is the same as bfw.zscore( X, [], 1 );
%     z = bfw.zscore1d( X, 'omitnan' ) excludes nan values from the mean
%     and standard deviation.
%
%     See also bfw.zscore
%
%     IN:
%       - `x` (data)
%       - `nanflag` (char) |OPTIONAL|
%     OUT:
%       - `z` (double)
%       - `mu` (double) 
%       - `sigma` (double)

if ( nargin < 2 ), nanflag = 'includenan'; end
[varargout{1:nargout}] = bfw.zscore( x, [], 1, nanflag );

end