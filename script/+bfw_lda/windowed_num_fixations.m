function [nfix, nfix_labels, edges] = windowed_num_fixations(events_file, window_dur, each, mask)

%%

validateattributes( window_dur, {'double'}, {'integer'}, mfilename, 'window duration' );

if ( nargin < 4 )
  mask = rowmask( events_file.labels );
end

start_times = bfw.event_column( events_file, 'start_time' );
each_I = findall( events_file.labels, each, mask );

nfix_labels = cell( size(each_I) );
nfix = cell( size(each_I) );
store_edges = cell( size(each_I) );

parfor i = 1:numel(each_I)
  subset_starts = start_times(each_I{i});
  
  roi_I = findall( events_file.labels, {'roi', 'looks_by', 'event_type'}, each_I{i} );
  
  min_start = min( subset_starts );
  max_start = max( subset_starts );
  
  bin_edges = floor(min_start):window_dur:ceil(max_start);
  
  if ( max(bin_edges) < max_start )
    bin_edges(end+1) = bin_edges(end) + window_dur;
  end
  
  tmp_counts = cell( size(roi_I) );
  tmp_labels = fcat();
  
  for j = 1:numel(roi_I)
    tmp_counts{j} = columnize( histc(start_times(roi_I{j}), bin_edges) );
    append1( tmp_labels, events_file.labels, roi_I{j}, numel(tmp_counts{j}) );
  end
  
  store_edges{i} = repmat( bin_edges(:), numel(roi_I), 1 );
  nfix{i} = vertcat( tmp_counts{:} );
  nfix_labels{i} = tmp_labels;
end

nfix = vertcat( nfix{:} );
nfix_labels = vertcat( fcat(), nfix_labels{:} );
edges = vertcat( store_edges{:} );

assert_ispair( nfix, nfix_labels );
assert_ispair( edges, nfix_labels );

end