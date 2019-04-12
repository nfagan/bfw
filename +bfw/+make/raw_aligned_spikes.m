function aligned_file = raw_aligned_spikes(files, varargin)

defaults = bfw.make.defaults.raw_aligned_spikes();
params = bfw.parsestruct( defaults, varargin );

events_subdir = params.events_subdir;

bfw.validatefiles( files, {events_subdir, 'spikes'} );

spike_file = shared_utils.general.get( files, 'spikes' );
events_file = shared_utils.general.get( files, events_subdir );

[events_file, event_indices] = handle_roi_selection( events_file, params.rois );
event_times = events_file.events(:, events_file.event_key('start_time'));

units = spike_file.data;
[t_series, starts, stops] = make_time_series( params );

use_window_start_as_0 = params.use_window_start_as_0;

binned_spikes = {};
binned_labels = fcat();
all_event_indices = [];

for i = 1:numel(units)
  unit = units(i);
  
  if ( check_skip_unit(unit, params) )
    continue;
  end
  
  [aligned, unit_labels] = align_unit( unit, event_times, starts, stops, use_window_start_as_0 );
  
  joined_labels = join( fcat.from(events_file), unit_labels );
  addsetcat( joined_labels, 'unit_index', sprintf('unit_index__%d', i) );
  
  append( binned_labels, joined_labels );
  binned_spikes = [ binned_spikes; aligned ];
  all_event_indices = [ all_event_indices; event_indices ];
end

[labels, categories] = categorical( binned_labels );

aligned_file = struct();
aligned_file.unified_filename = bfw.try_get_unified_filename( events_file );
aligned_file.params = params;
aligned_file.spikes = binned_spikes;
aligned_file.labels = labels;
aligned_file.categories = categories;
aligned_file.t = t_series;
aligned_file.n_events_per_unit = numel( event_times );
aligned_file.event_indices = all_event_indices;

end

function [t_series, starts, stops] = make_time_series(params)

lb = params.look_back;
ss = params.step_size;
la = params.look_ahead;
ws = params.window_size;

t_series = lb:ss:la;

starts = t_series - ws / 2;
stops = starts + ws;

end

function [mat_spikes, labels] = align_unit(unit, events, starts, stops, window_start_as_0)

spike_times = unit.times;

mat_spikes = cell( numel(events), numel(starts) );

for i = 1:numel(events)
  evt = events(i);
  
  if ( isnan(evt) )
    continue;
  end
  
  start = starts + evt;
  stop = stops + evt;
  
  for j = 1:numel(start)
    subset_spikes = spike_times(spike_times >= start(j) & spike_times < stop(j));
    
    if ( window_start_as_0 )
      subset_spikes = subset_spikes - start(j);
    end
    
    mat_spikes{i, j} = subset_spikes(:);   
  end
end

labels = fcat.from( bfw.get_unit_labels(unit) );

end

function [events_file, event_indices] = handle_roi_selection(events_file, rois)

rois = cellstr( rois );

if ( numel(rois) == 1 && strcmp(rois, 'all') )
  return
end

roi_ind = strcmp( events_file.categories, 'roi' );
assert( nnz(roi_ind) == 1, 'Found %d ''roi'' categories; expected 1.', nnz(roi_ind) );

matches_roi = cellfun( @(x) any(strcmp(rois, x)), events_file.labels(:, roi_ind) );

events_file.labels(~matches_roi, :) = [];
events_file.events(~matches_roi, :) = [];

event_indices = find( matches_roi );

end

function tf = check_skip_unit(unit, params)

tf = params.remove_rating_0_units && isfield( unit, 'rating' ) && unit.rating == 0;

end