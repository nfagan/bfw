function outs = positional_info(varargin)

defaults = bfw.get_common_make_defaults();
defaults.config = bfw_st.default_config();
defaults.look_back = 0;
defaults.look_ahead = 5;
defaults.source_rois = 'all';
defaults.target_rois = 'all';
defaults.non_overlapping_pairs = {{'eyes_nf', 'face'}};
defaults.non_overlapping_each = { 'looks_by', 'event_type' };
defaults.use_events = true;
defaults.event_duration_criterion = 1;

inputs = { 'raw_events', 'stim', 'meta', 'stim_meta' ...
  , 'plex_start_stop_times', 'rois' ...
  , 'aligned_binned_raw_samples/position', 'aligned_binned_raw_samples/time' ...
  , 'aligned_binned_raw_samples/raw_eye_mmv_fixations' ...
};

[params, runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();

results = runner.run( @main, params );
outputs = shared_utils.pipeline.extract_outputs_from_results( results );

if ( isempty(outputs) )
  outs = struct();
  outs.distances = [];
  outs.relative_start_times = [];
  outs.distance_labels = fcat();
else
  outs = shared_utils.struct.soa( outputs ); 
end

end

function outs = main(files, params)

[event_file, stim_file, meta_file, stim_meta_file, start_time_file, roi_file, pos_file, t_file, fix_file] = ...
  get_files( files, 'raw_events', 'stim', 'meta', 'stim_meta' ...
  , 'plex_start_stop_times', 'rois', 'position', 'time', 'raw_eye_mmv_fixations' );

if ( params.use_events )
  event_file = handle_rois_and_non_overlapping_events( event_file, params );
else
  dur_crit = params.event_duration_criterion;
  event_file = make_dummy_event_file_from_fix_file( fix_file, t_file, event_file, dur_crit );
end

% Extract the stim times and labels for each stim.
[stim_ts, stim_labels] = bfw_st.files_to_pair( stim_file, stim_meta_file, meta_file );
update_stim_labels( stim_labels, stim_ts );

monk_ids = intersect( fieldnames(pos_file), {'m1', 'm2'} );

dist_labels = fcat();
distances = [];
relative_start_times = [];

for i = 1:numel(monk_ids)
  m_id = monk_ids{i};

  [roi_names, roi_centers] = extract_roi_centers( roi_file.(m_id).rects );
  [roi_names, roi_centers] = filter_target_rois( roi_names, roi_centers, cellstr(params.target_rois) );

  pos = pos_file.(m_id);
  m_event_file = bfw.keep_events( event_file, bfw.matches_looks_by(event_file, m_id) );

  for j = 1:numel(stim_ts)
    outs = distance_between_gaze_and_roi( m_event_file, t_file, stim_ts(j) ...
      , pos, roi_names, roi_centers, params );
    join( outs.labels, prune(stim_labels(j)) );

    append( dist_labels, outs.labels );
    distances = [ distances; outs.distances ];
    relative_start_times = [ relative_start_times; outs.relative_start_times ];
  end
end

assert_ispair( distances, dist_labels );
assert_ispair( relative_start_times, dist_labels );

outs = struct();
outs.distances = distances;
outs.relative_start_times = relative_start_times;
outs.distance_labels = dist_labels;

end

function outs = distance_between_gaze_and_roi(event_file, t_file, stim_time, pos, roi_names, roi_centers, params)

window_start = stim_time + params.look_back;
window_stop = stim_time + params.look_ahead;

non_nan_ind = find( ~isnan(t_file.t) );
non_nan_t = t_file.t(non_nan_ind);

event_starts = bfw.event_column( event_file, 'start_time' );
event_stops = bfw.event_column( event_file, 'stop_time' );

within_t_bounds = find( arrayfun(@(x) x >= window_start & x < window_stop, event_starts) );
start_inds = non_nan_ind(bfw.find_nearest(non_nan_t, event_starts(within_t_bounds)));
stop_inds = non_nan_ind(bfw.find_nearest(non_nan_t, event_stops(within_t_bounds)));

relative_start_times = event_starts(within_t_bounds) - stim_time;

event_pos = arrayfun( @(x, y) nanmean(pos(:, x:y), 2), start_inds, stop_inds, 'un', 0 );
event_pos = horzcat( event_pos{:} )';

distances = cell( size(roi_names) );

event_labels = fcat.from( event_file.labels(within_t_bounds, :), event_file.categories );
renamecat( event_labels, 'roi', 'source_roi' );

out_labels = fcat();

for i = 1:numel(roi_names)  
  r = roi_centers{i};
  
  if ( ~isempty(event_pos) )
    distances{i} = bfw.distance( event_pos(:, 1), event_pos(:, 2), r(1), r(2) );
  end
  
  join( event_labels, fcat.create('target_roi', sprintf('target_%s', roi_names{i})) );
  append( out_labels, event_labels );
end

distances = vertcat( distances{:} );
assert_ispair( distances, out_labels );

outs = struct();
outs.distances = distances;
outs.relative_start_times = repmat( relative_start_times(:), numel(roi_names), 1 );
outs.labels = out_labels;

end

function varargout = get_files(files, varargin)

varargout = eachcell( @(x) shared_utils.general.get(files, x), varargin );

end

function [roi_names, roi_centers] = filter_target_rois(roi_names, roi_centers, rois)

if ( ischar(rois) && strcmp(rois, 'all') )
  return
end

matches = ismember( roi_names, rois );
roi_names = roi_names(matches);
roi_centers = roi_centers(matches);

end

function update_stim_labels(stim_labels, stim_ts)

bfw_st.add_per_stim_labels( stim_labels, stim_ts );
prune( stim_labels );

end

function [roi_names, roi_centers] = extract_roi_centers(rects)

roi_names = keys( rects );
roi_centers = cell( size(roi_names) );

for i = 1:numel(roi_names)
  roi_centers{i} = shared_utils.rect.center( rects(roi_names{i}) );
end

end

function event_file = make_dummy_event_file_from_fix_file(fix_file, t_file, in_event_file, event_duration_criterion)

event_file = bfw.keep_events( in_event_file, [] );
event_file.event_key = containers.Map();
event_file.event_key('start_time') = 1;
event_file.event_key('stop_time') = 2;

fs = intersect( {'m1', 'm2'}, fieldnames(fix_file) );

for i = 1:numel(fs)
  [dummy_events, durs] = shared_utils.logical.find_islands( fix_file.(fs{i}) );
  meets_crit = durs >= event_duration_criterion;

  dummy_events = dummy_events(meets_crit);
  dummy_event_t_starts = t_file.t(dummy_events);
  dummy_event_t_stops = t_file.t(dummy_events + durs(meets_crit)-1);

  is_non_nan = ~isnan( dummy_event_t_starts ) & ~isnan( dummy_event_t_stops );
  starts = dummy_event_t_starts(is_non_nan);
  stops = dummy_event_t_stops(is_non_nan);

  looks_by = repmat( fs(i), numel(starts), 1 );
  initiator = repmat( {sprintf('%s_initiated', fs{i})}, size(looks_by) );
  term = repmat( {sprintf('%s_terminated', fs{i})}, size(looks_by) );
  event_type = repmat( {'exclusive_event'}, size(looks_by) );
  roi = repmat( {'anywhere'}, size(looks_by) );

  start_stop = [starts(:), stops(:)];
  
  if ( isempty(event_file.events) )
    event_file.events = start_stop;
  else
    event_file.events = [ event_file.events; start_stop ];
  end

  event_file.labels = [ event_file.labels; [looks_by(:), initiator(:), term(:), event_type(:), roi(:)] ];
end

end

function events_file = handle_rois_and_non_overlapping_events(events_file, params)

rois = params.source_rois;

if ( ischar(rois) && strcmp(rois, 'all') )
  rois = {};
end

non_overlapping_pairs = params.non_overlapping_pairs;
each = params.non_overlapping_each;

events_file = bfw_st.make_non_overlapping_events_file( events_file, rois, non_overlapping_pairs, each );

end