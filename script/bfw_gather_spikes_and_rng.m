function outs = bfw_gather_spikes_and_rng(varargin)

defaults = bfw.get_common_make_defaults();
defaults.window_size = 0.05;
defaults.step_size = 0.05;
defaults.look_back = -0.5;
defaults.look_ahead = 0.5;
defaults.rois = {'eyes_nf', 'face', 'outside1'};
defaults.collapse_nonsocial_object_rois = true;
defaults.spike_func = @(x, t) deal(x, t);
defaults.non_overlapping_mask_inputs = {};
defaults.exclude_all_overlapping = true;
defaults.non_overlapping_pairs = bfw_get_non_overlapping_pairs();
defaults.spike_dir = 'spikes';
defaults.events_subdir = 'raw_events';
defaults.is_already_non_overlapping = false;
defaults.include_rng = true;
defaults.include_rasters = false;
defaults.preserve_output = true;
defaults.output_directory = '';

p = bfw.parsestruct( defaults, varargin );
spike_dir = validatestring( p.spike_dir, {'spikes', 'cc_spikes'}, mfilename, 'spike_dir' );

inputs = { p.events_subdir, spike_dir, 'meta' };
if ( p.include_rng )
  inputs{end+1} = 'rng';
end

output_dir = '';
if ( ~p.preserve_output )
  output_dir = p.output_directory;
end

[params, loop_runner] = bfw.get_params_and_loop_runner( ...
  inputs, output_dir, defaults, varargin );
if ( params.preserve_output )
  loop_runner.convert_to_non_saving_with_output();
end

results = loop_runner.run( @gather_spikes, params );
outputs = [ results([results.success]).output ];

empties = arrayfun( @(x) isempty(x.spikes), outputs );
outputs = outputs(~empties);

outs = struct();

if ( isempty(outputs) )
  outs.labels = fcat;
  outs.spikes = [];
  outs.session = {};
  outs.has_rng_state = logical( [] );
  outs.rng_state = {};
  outs.t = [];
  outs.events = [];
  outs.event_labels = fcat();
  outs.event_key = containers.Map();
  outs.rasters = [];
else
  outs.labels = vertcat( fcat(), outputs.labels );
  outs.spikes = vertcat( outputs.spikes );
  outs.rasters = vertcat( outputs.rasters );
  outs.session = vertcat( outputs.session );
  outs.t = outputs(1).t;
  outs.events = vertcat( outputs.events );
  outs.event_labels = vertcat( fcat, outputs.event_labels );
  outs.event_key = outputs(1).event_key;
  
  if ( p.include_rng )
    outs.has_rng_state = [ outputs.has_rng_state ]';
    outs.rng_state = { outputs.rng_state }';
  end
end

end

function outs = gather_spikes(files, params)

if ( strcmp(params.spike_dir, 'cc_spikes') )
  files('spikes') = files('cc_spikes');
end

[files, was_link] = require_spike_file( bfw.gid(params.spike_dir, params.config), files );

aligned_spike_file = bfw.make.raw_aligned_spikes( files ...
  , 'window_size', params.window_size ...
  , 'step_size', params.step_size ...
  , 'look_back', params.look_back ...
  , 'look_ahead', params.look_ahead ...
  , 'rois', params.rois ...
  , 'events_subdir', params.events_subdir ...
);

meta_file = shared_utils.general.get( files, 'meta' );
events_file = shared_utils.general.get( files, params.events_subdir );

if ( params.include_rng )
  rng_file = shared_utils.general.get( files, 'rng' );
end

[spikes, t] = feval( params.spike_func, aligned_spike_file.spikes, aligned_spike_file.t );
spike_labels = fcat.from( aligned_spike_file );

if ( params.collapse_nonsocial_object_rois )
  collapse_nonsocial_object_rois( spike_labels );
end

if ( params.is_already_non_overlapping )
  % No need to exclusive-ize events; initially use all of them.
  non_overlapping = rowmask( events_file.labels );
else
  if ( ~isempty(params.non_overlapping_mask_inputs) )
    non_overlapping_mask = fcat.mask( fcat.from(events_file) ...
      , params.non_overlapping_mask_inputs{:} );
  else
    non_overlapping_mask = rowmask( events_file.labels );
  end

  if ( params.exclude_all_overlapping )
    overlap_rois = {};
  else
    overlap_rois = params.rois;
  end

  % Subset of rows of spike_labels that contain events that are non-overlapping
  non_overlapping = get_non_overlapping_event_indices( events_file, params.non_overlapping_pairs ...
    , overlap_rois, non_overlapping_mask );
end

ok_event_inds = find( ismember(aligned_spike_file.event_indices, non_overlapping) );

join( spike_labels, bfw.struct2fcat(meta_file) );

prune( keep(spike_labels, ok_event_inds) );
spikes = spikes(ok_event_inds, :);

if ( params.include_rasters )
  rasters = compute_rasters( aligned_spike_file.spikes, aligned_spike_file.event_times );
  rasters = rasters(ok_event_inds, :);
else
  rasters = [];
end

% Keep matching events
event_labels = events_file.labels(aligned_spike_file.event_indices, :);
events = events_file.events(aligned_spike_file.event_indices, :);
events = events(ok_event_inds, :);
event_labels = event_labels(ok_event_inds, :);

outs = struct();
outs.labels = spike_labels;
outs.spikes = spikes;
outs.rasters = rasters;
outs.session = combs( spike_labels, 'session' );
outs.has_rng_state = ~was_link && params.include_rng;
outs.t = t;
outs.events = events;
outs.event_labels = fcat.from( event_labels, events_file.categories );
outs.event_key = events_file.event_key;

if ( ~was_link && params.include_rng )
  outs.rng_state = rng_file.state;
else
  outs.rng_state = {};
end

end

function rasters = compute_rasters(spikes, event_times)

assert( size(spikes, 1) == numel(event_times) );

rasters = cell( size(spikes) );
for i = 1:size(spikes, 1)
  for j = 1:size(spikes, 2)
    rasters{i, j} = spikes{i, j} - event_times(i);
  end
end

end

function non_overlapping = get_non_overlapping_event_indices(events_file, pairs, rois, mask)

if ( ~isempty(rois) )
  is_pair_with_roi = cellfun( @(x) all(ismember(x, rois)), pairs );
  pairs = pairs(is_pair_with_roi);
end

non_overlapping = bfw_exclusive_events_from_events_file( events_file, pairs, {}, mask );
non_nan = bfw_non_nan_linearized_event_times( events_file );

non_overlapping = intersect( non_overlapping, non_nan );

end

function [files, was_link] = require_spike_file(spike_p, files)

spike_file = shared_utils.general.get( files, 'spikes' );
was_link = spike_file.is_link;

if ( was_link )
  spike_file = shared_utils.io.fload( fullfile(spike_p, spike_file.data_file) );
  
  files = shared_utils.general.set( files, 'spikes', spike_file );
end

end

function labels = collapse_nonsocial_object_rois(labels)

if ( isempty(labels) )
  return;
end

left_ind = find( labels, 'left_nonsocial_object' );
right_ind = find( labels, 'right_nonsocial_object' );
setcat( labels, 'roi', 'nonsocial_object', union(left_ind, right_ind) );

left_ind_matched = find( labels, 'left_nonsocial_object_eyes_nf_matched' );
right_ind_matched = find( labels, 'right_nonsocial_object_eyes_nf_matched' );
setcat( labels, 'roi', 'nonsocial_object_eyes_nf_matched', union(left_ind_matched, right_ind_matched) );

end

function [counts, t] = spike_counts(spikes, t)

counts = cellfun( @numel, spikes );

end