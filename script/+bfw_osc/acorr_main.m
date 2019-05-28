function outs = acorr_main(spikes_events, session_I, varargin)

defaults = bfw_osc.acorr_main_defaults();
params = bfw.parsestruct( defaults, varargin );

rois = cellstr( params.rois );
assert( ~isempty(params.freq_window), 'Specify a `freq_window`.' );

all_outs = {};

parfor i = 1:numel(session_I)
  shared_utils.general.progress( i, numel(session_I) );
  
  run_inds = session_I{i};
  spike_filename = unique( spikes_events.spike_filenames(run_inds) );
  assert( numel(spike_filename) == 1 );
  
  spike_file = spikes_events.spike_files(spike_filename{1});
  [event_file, event_labs] = concat_event_files( spikes_events, rois, run_inds );
  
  interval_spec = params.interval_specificity;
  [intervals, interval_labels] = ...
    make_event_intervals( event_file, event_labs, interval_spec, rowmask(event_labs) );
    
  all_outs{i} = run_acorr( spike_file, intervals, interval_labels, params );
end

all_outs = [ all_outs{:} ];

outs = struct();

if ( isempty(all_outs) )
  outs.labels = fcat();
  outs.psd = [];
  outs.f = [];
  outs.osc_info = [];
  outs.acorr = [];
  outs.acorr_bin_centers = [];
else
  outs.labels = vertcat( fcat, all_outs.labels );
  outs.psd = vertcat( all_outs.psd );
  outs.f = all_outs(1).f;
  outs.osc_info = vertcat( all_outs.osc_info );
  outs.acorr = vertcat( all_outs.acorr );
  outs.acorr_bin_centers = vertcat( all_outs.acorr_bin_centers );
end

end

function out = run_acorr(spike_file, intervals, interval_labels, params)

freq_window = params.freq_window;
deg_thresh = params.peak_degree_threshold;

units = spike_file.data;

acorr_labels = fcat();

psds = [];
psd_fs = [];

osc_info = [];

acorr_traces = [];
acorr_bin_centers = [];

for i = 1:numel(units)
  spike_ts = units(i).times;
  unit_labs = bfw.unit_struct_to_fcat( units(i) );
  merge( interval_labels, unit_labs );
  
  for j = 1:numel(intervals)
    use_spikes = spike_ts(is_within_interval(spike_ts, intervals{j}));
    
    if ( isempty(use_spikes) )
      continue;
    end
    
    is_ok = true;
    
    try
      [bin_centers, smoothed_acorr] = ...
        bfw_osc.fast_peakless_acorr( use_spikes, freq_window, deg_thresh );
      [f, psd] = bfw_osc.acorr_psd( smoothed_acorr );
      [f_osc, osc_score] = bfw_osc.osc_score( f, psd, freq_window );
      
    catch err
      warning( err.message );
      is_ok = false;
    end
    
    if ( is_ok )
      psds = [ psds; psd(:)' ];
      psd_fs = [ psd_fs; f(:)' ];

      osc_info = [ osc_info; [f_osc, osc_score] ];

      acorr_traces = [ acorr_traces; smoothed_acorr ];
      acorr_bin_centers = [ acorr_bin_centers; bin_centers ];

      append( acorr_labels, interval_labels, j );
    end
  end
end

out = struct();
out.labels = acorr_labels;
out.psd = psds;
out.f = psd_fs;
out.osc_info = osc_info;
out.acorr = acorr_traces;
out.acorr_bin_centers = acorr_bin_centers;

end

function [event_file, event_labs] = concat_event_files(spikes_events, rois, run_inds)

event_file = struct( [] );
event_labs = fcat();

for i = 1:numel(run_inds)
  tmp_event_file = spikes_events.event_files(run_inds(i));
  tmp_event_labs = fcat.from( tmp_event_file.labels, tmp_event_file.categories );
  join( tmp_event_labs, prune(spikes_events.meta_labs(run_inds(i))) );
  
  event_mask = rowmask( tmp_event_labs );

  non_overlapping_inds = get_non_overlapping_event_indices( tmp_event_file, rois, event_mask );

  roi_ind = find( tmp_event_labs, rois, non_overlapping_inds );
  collapse_object_rois( tmp_event_labs );
  
  tmp_event_file.labels = tmp_event_file.labels(roi_ind, :);
  tmp_event_file.events = tmp_event_file.events(roi_ind, :);
  prune( keep(tmp_event_labs, roi_ind) );
  
  append( event_labs, tmp_event_labs );
  
  if ( i == 1 )
    event_file = tmp_event_file;
  else
    event_file.labels = [ event_file.labels; tmp_event_file.labels ];
    event_file.events = [ event_file.events; tmp_event_file.events ];
  end
end

end

function tf = is_within_interval(spike_ts, intervals)

tf = false( size(spike_ts) );

for i = 1:size(intervals, 1)
  start_interval = intervals(i, 1);
  stop_interval = intervals(i, 2);
  
  tf = tf | (spike_ts >= start_interval & spike_ts < stop_interval);
end

end

function [diffed_intervals, interval_labs] = make_event_intervals(event_file, event_labs, spec, mask)

[interval_labs, interval_I] = keepeach( event_labs', spec, mask );

start_ts = event_file.events(:, event_file.event_key('start_time'));
stop_ts = event_file.events(:, event_file.event_key('stop_time'));

intervals = cell( numel(interval_I), 1 );
all_inds = cell( size(intervals) );

for i = 1:numel(interval_I)
  interval_ind = interval_I{i};
  
  start_t = start_ts(interval_ind);
  stop_t = stop_ts(interval_ind);
  
  [~, sorted_ind] = sort( start_t );
  
  intervals{i} = [ start_t(sorted_ind), stop_t(sorted_ind) ];
  all_inds{i} = repmat( i, numel(sorted_ind), 1 );
end

all_intervals = vertcat( intervals{:} );
all_inds = vertcat( all_inds{:} );

[~, sorted_ind] = sort( all_intervals(:, 1) );

all_intervals = all_intervals(sorted_ind, :);
all_inds = all_inds(sorted_ind, :);

diffed_inds = diff( all_inds );
diff_stops = find( [false; diffed_inds ~= 0] );

diffed_intervals = cell( numel(interval_I), 1 );

for i = 1:numel(diff_stops)
  diff_stop = diff_stops(i)-1;
  prev_ind = all_inds(diff_stop);
  diff_start = diff_stop;
  
  while ( diff_start > 1 && all_inds(diff_start-1) == prev_ind )
    diff_start = diff_start - 1;
  end
  
  % Interval start is start of this event.
  interval_start = all_intervals(diff_start, 1);
  % Interval stop is the start of the *next* event type.
  interval_stop = all_intervals(diff_stop+1, 1);
  
  diffed_intervals{prev_ind}(end+1, :) = [ interval_start, interval_stop ];
end

end

function event_labs = collapse_object_rois(event_labs)

replace( event_labs, {'left_nonsocial_object', 'right_nonsocial_object'}, 'nonsocial_object' );
prune( event_labs );

end

function non_overlapping = get_non_overlapping_event_indices(events_file, rois, mask)

pairs = bfw_get_non_overlapping_pairs();

if ( ~isempty(rois) )
  is_pair_with_roi = cellfun( @(x) all(ismember(x, rois)), pairs );
  pairs = pairs(is_pair_with_roi);
end

non_overlapping = bfw_exclusive_events_from_events_file( events_file, pairs, {}, mask );
non_nan = bfw_non_nan_linearized_event_times( events_file );

non_overlapping = intersect( non_overlapping, non_nan );

end