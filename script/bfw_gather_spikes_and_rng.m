function outs = bfw_gather_spikes_and_rng(varargin)

defaults = bfw.get_common_make_defaults();
defaults.window_size = 0.05;
defaults.step_size = 0.05;
defaults.look_back = -0.5;
defaults.look_ahead = 0.5;
defaults.rois = {'eyes_nf', 'face', 'outside1'};
defaults.collapse_nonsocial_object_rois = true;
defaults.spike_func = @(x, t) deal(x, t);

inputs = { 'raw_events', 'spikes', 'meta', 'rng' };

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
loop_runner.convert_to_non_saving_with_output();

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
else
  outs.labels = vertcat( fcat(), outputs.labels );
  outs.spikes = vertcat( outputs.spikes );
  outs.session = vertcat( outputs.session );
  outs.has_rng_state = [ outputs.has_rng_state ]';
  outs.rng_state = { outputs.rng_state }';
  outs.t = outputs(1).t;
end

end

function outs = gather_spikes(files, params)

[files, was_link] = require_spike_file( bfw.gid('spikes', params.config), files );

aligned_spike_file = bfw.make.raw_aligned_spikes( files ...
  , 'window_size', params.window_size ...
  , 'step_size', params.step_size ...
  , 'look_back', params.look_back ...
  , 'look_ahead', params.look_ahead ...
  , 'rois', params.rois ...
);

meta_file = shared_utils.general.get( files, 'meta' );
rng_file = shared_utils.general.get( files, 'rng' );
events_file = shared_utils.general.get( files, 'raw_events' );

[spikes, t] = feval( params.spike_func, aligned_spike_file.spikes, aligned_spike_file.t );
spike_labels = fcat.from( aligned_spike_file );

if ( params.collapse_nonsocial_object_rois )
  collapse_nonsocial_object_rois( spike_labels );
end

% Subset of rows of spike_labels that contain events that are non-overlapping
non_overlapping = get_non_overlapping_event_indices( events_file );
ok_event_inds = find( ismember(aligned_spike_file.event_indices, non_overlapping) );

join( spike_labels, bfw.struct2fcat(meta_file) );

prune( keep(spike_labels, ok_event_inds) );
spikes = spikes(ok_event_inds, :);

outs = struct();
outs.labels = spike_labels;
outs.spikes = spikes;
outs.session = combs( spike_labels, 'session' );
outs.has_rng_state = ~was_link;
outs.t = t;

if ( ~was_link )
  outs.rng_state = rng_file.state;
else
  outs.rng_state = {};
end

end

function non_overlapping = get_non_overlapping_event_indices(events_file)

non_overlapping = bfw_exclusive_events_from_events_file( events_file );
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

end

function [counts, t] = spike_counts(spikes, t)

counts = cellfun( @numel, spikes );

end