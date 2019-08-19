function varargout = stim_minus_sham(data, labels, each, mask)

if ( nargin < 4 )
  mask = rowmask( labels );
end

[varargout{1:nargout}] = dsp3.summary_binary_op( data, labels, each, 'stim', 'sham' ...
  , @minus, @(x) nanmean(x, 1), mask );

end