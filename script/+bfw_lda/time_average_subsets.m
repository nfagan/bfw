function out_data = time_average_subsets(data, labels, t, selector_combinations, t_windows, mask, find_func)

assert_ispair( data, labels );
assert( iscell(selector_combinations) && iscell(t_windows) && ...
  numel(selector_combinations) == numel(t_windows) ...
  , 'Selector combinations and time windows must be cell arrays with the same number of elements.' );
assert( numel(t) == size(data, 2), 'Time points do not correspond to number of columns of data.' );

if ( nargin < 6 )
  mask = rowmask( labels );
end

if ( nargin < 7 )
  find_func = @(labels, selectors, mask) find(labels, selectors, mask);
end

out_data = nan( rows(data), 1 );

for i = 1:numel(selector_combinations)
  label_ind = find_func( labels, selector_combinations{i}, mask );
  t_ind = t >= t_windows{i}(1) & t <= t_windows{i}(2);
  out_data(label_ind) = nanmean( data(label_ind, t_ind), 2 );
end

end