function [ids, spike_inds] = collect_spikes(spike_matrix, unit_row, time_row)

if ( nargin < 3 )
  time_row = 2;
end
if ( nargin < 2 )
  unit_row = 3;
end

validateattributes( spike_matrix, {'double'}, {'2d', 'nrows', 3} ...
  , mfilename, 'spike_matrix' );

[ids, ~, ic] = unique( spike_matrix(unit_row, :) );
inds = groupi( ic );
spike_inds = cell( numel(inds), 1 );
for i = 1:numel(inds)
  spike_inds{i} = spike_matrix(time_row, inds{i});
end

end