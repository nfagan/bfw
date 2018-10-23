function [z,mu,sigma] = zscore(x, flag, dim, nanflag)

%   ZSCORE -- Z-score normalize data, optionally excluding nan.
%
%     z = bfw.zscore( X, flag, dim ) is the same as zscore( X, flag, dim ).
%     z = bfw.zscore( ..., 'includenan' ) is also the same.
%     z = bfw.zscore( ..., 'omitnan' ) excludes nan values from the mean or
%     standard deviation.
%
%     See also zscore

if isequal(x,[]), z = x; return; end

if nargin < 2, flag = 0; end

if nargin < 3
  dim = find(size(x) ~= 1, 1);
  if isempty(dim), dim = 1; end
end

if ( nargin < 4 )
  nanflag = 'includenan';
else
  validateattributes( nanflag, {'char'}, {}, 'zscore', 'nanflag' );
end

[mfunc, sfunc] = get_nan_func( nanflag );

% Compute X's mean and sd, and standardize it
mu = mfunc(x,dim);
sigma = sfunc(x,flag,dim);
sigma0 = sigma;
sigma0(sigma0==0) = 1;
z = bsxfun(@minus, x, mu);
z = bsxfun(@rdivide, z, sigma0);

end

function [mfunc, sfunc] = get_nan_func(flag)

if ( strcmpi(flag, 'includenan') )
  mfunc = @mean;
  sfunc = @std;
elseif ( strcmpi(flag, 'omitnan') )
  mfunc = @nanmean;
  sfunc = @nanstd;
else
  flags = strjoin( {'includenan', 'omitnan'}, ' | ' );
  error( 'Unrecognized flag "%s"; options are: \n\n%s', flag, flags );
end

end