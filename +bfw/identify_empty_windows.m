function [windows, is_empty_window, labels] = identify_empty_windows(spike_times, spike_labels, start_stops, start_stop_labels, window_size)

assert_ispair( spike_times, spike_labels );
assert_ispair( start_stops, start_stop_labels );

[start_stop_ind, sessions] = findall( start_stop_labels, 'session' );

windows = cell( numel(start_stop_ind), 1 );
labels = cell( size(windows) );
is_empty_window = cell( size(windows) );

for i = 1:numel(start_stop_ind)
  times = start_stops(start_stop_ind{i}, :);
  
  assert( numel(times) == 2, 'Expected 2 elements for start stop times; got %d', numel(times) );
  
  min_t = floor( min(times) );
  max_t = ceil( max(times) );
  
  windowed_t = min_t:window_size:max_t;
  
  if ( windowed_t(end) < max_t )
    windowed_t(end+1) = windowed_t(end) + window_size;
  end
  
  % extra bin for histc.
  windowed_t(end+1) = windowed_t(end) + window_size;
  
  spike_mask = fcat.mask( spike_labels ...
    , @find, sessions{i} ...
    , @findnone, bfw.nan_unit_uuid ...
  );
  
  tmp_windows = repmat( {columnize(windowed_t(1:end-1))}, numel(spike_mask), 1 );
  tmp_missing_spike = cell( numel(spike_mask), 1 );
  tmp_spike_labs = fcat();
  
  for j = 1:numel(spike_mask)    
    spike_ts = spike_times{spike_mask(j)};
    counts = histc( spike_ts, windowed_t );
    
    tmp_missing_spike{j} = counts(1:end-1) == 0;
    append1( tmp_spike_labs, spike_labels, spike_mask(j), numel(tmp_missing_spike{j}) );
  end
  
  windows{i} = vertcat( tmp_windows{:} );
  is_empty_window{i} = vertcat( tmp_missing_spike{:} );
  labels{i} = tmp_spike_labs;
end

windows = vertcat( windows{:} );
is_empty_window = vertcat( is_empty_window{:} );
labels = vertcat( fcat, labels{:} );

end