function ind = find_non_empty_windows(starts, stops, spike_labels, windows, is_empty, window_labels, spike_mask)

assert_ispair( starts, spike_labels );
assert_ispair( stops, spike_labels );
assert_ispair( windows, window_labels );
assert_ispair( is_empty, window_labels );

if ( nargin < 7 )
  spike_mask = rowmask( starts );
end

[unit_ind, unit_C] = findall( spike_labels, {'unit_uuid', 'session', 'region'}, spike_mask );
to_keep = cell( numel(unit_ind), 1 );

for i = 1:numel(unit_ind)
  window_ind = find( window_labels, unit_C(:, i) );
  subset_windows = windows(window_ind);
  subset_empties = is_empty(window_ind);
  
  subset_starts = starts(unit_ind{i});
  subset_stops = stops(unit_ind{i});
  to_remove = true( size(subset_starts) );
  
  max_subset_win = max( subset_windows );
  
  if ( ~isempty(window_ind) )
    for j = 1:numel(subset_starts)
      start = subset_starts(j);
      stop = subset_stops(j);
      
      if ( ~isfinite(start) || ~isfinite(stop) )
        continue;
      end
      
      stop = min( stop, max_subset_win );

      min_win = find( subset_windows >= start, 1, 'first' );
      if ( ~isempty(min_win) && min_win ~= start )
        min_win = min_win - 1;
      end

      max_win = find( subset_windows >= stop, 1, 'first' );
      if ( ~isempty(max_win) && max_win ~= stop )
        max_win = max_win - 1;
      end
      
%       assert( ~isempty(min_win) && ~isempty(max_win) );
      if ( isempty(min_win) || isempty(max_win) )
        continue;
      end
      
      to_remove(j) = all(subset_empties(min_win:max_win));
    end
  end
  
  to_keep{i} = unit_ind{i}(~to_remove);
end

ind = vertcat( to_keep{:} );

end