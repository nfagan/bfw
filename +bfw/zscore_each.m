function [zdat, I] = zscore_each(data, labs, spec, varargin)

%   ZSCORE_EACH -- Z-score normalize data, for each subset.
%
%     data = ... zscore_each( data, labels, spec ); z-scores normalizes
%     `data` across the first dimension, drawing means and standard
%     deviations from subsets of `data` identified by each unique
%     combination of labels in `spec` categories.
%
%     data = ... zscore_each( ..., mask ); selects from rows identified by
%     the uint64 index vector `mask`.
%
%     See also bfw.zscore1d, bfw.zscore, fcat/findall
%
%     IN:
%       - `data` (double)
%       - `labs` (fcat)
%       - `spec` (cell array of strings, char)
%       - `mask` (uint64) |OPTIONAL|
%     OUT:
%       - `data` (double)
%       - `I` (cell array of uint64)

assert_ispair( data, labs );

I = findall( labs, spec, varargin{:} );

zdat = nan( size(data) );
cols = colons( ndims(data)-1 );

for i = 1:numel(I)
  zdat(I{i}, cols{:}) = bfw.zscore1d( data(I{i}, cols{:}), 'omitnan' );
end

end