function outs = make_gaze_reward_components(gaze_counts, gaze_data_type, reward_counts, varargin)

defaults = struct();
defaults.use_empty_window_criterion = true;
defaults.median_split_duration = false;
defaults.windows = [];
defaults.is_empty_window = [];
defaults.empty_window_labels = fcat();
defaults.nfix_window_duration = 5;

params = bfw.parsestruct( defaults, varargin );

use_empty_window_criterion = params.use_empty_window_criterion;
windows = params.windows;
is_empty_window = params.is_empty_window;
empty_window_labels = params.empty_window_labels;
median_split_duration = params.median_split_duration;

[gc, gc_mask, gaze_params] = bfw_lda.make_gaze_components( gaze_counts, gaze_data_type ...
  , 'nfix_window_dur', params.nfix_window_duration ...
  , 'windows', windows ...
  , 'is_empty_window', is_empty_window ...
  , 'empty_window_labels', empty_window_labels ...
  , 'apply_empty_window_mask', use_empty_window_criterion ...
);

if ( median_split_duration )
  if ( strcmp(gaze_data_type, 'spikes') )
    [gc_duration, gc_duration_mask] = bfw_lda.make_gaze_components( gaze_counts, 'duration' ...
      , 'windows', windows ...
      , 'is_empty_window', is_empty_window ...
      , 'empty_window_labels', empty_window_labels ...
      , 'apply_empty_window_mask', use_empty_window_criterion ...
    );
  
    gc_mask = intersect( gc_mask, gc_duration_mask );  
    use_duration = gc_duration.psth;
  else
    assert( strcmp(gaze_data_type, 'duration'), 'Expected gaze data type to be spikes or duration.' );
    use_duration = gc.psth;
  end
  
  med_split_each = { 'roi', 'looks_by', 'event_type', 'session' };
  bfw_lda.add_median_split_duration_labels( gc.labels, use_duration, med_split_each, gc_mask );
end

if ( ~strcmp(gaze_data_type, 'spikes') )
  gc_spikes = bfw_lda.make_gaze_components( gaze_counts, 'spikes' );
  
  if ( use_empty_window_criterion )
    gc_spike_mask = bfw.find_non_empty_windows( gc_spikes.start_times, gc_spikes.stop_times, gc_spikes.labels ...
      , windows, is_empty_window, empty_window_labels );
  else
    gc_spike_mask = rowmask( gc_spikes.psth );
  end
  
  if ( median_split_duration && strcmp(gaze_data_type, 'duration') )
    gc_spike_mask = intersect( gc_spike_mask, gc_mask );
    bfw_lda.add_median_split_duration_labels( gc_spikes.labels, gc.psth, med_split_each, gc_spike_mask );
  end
else
  gc_spikes = gc;
  gc_spike_mask = gc_mask;
end

[rc, reward_params] = bfw_lda.make_reward_component( reward_counts );
target_event_names = setdiff( reward_params.event_names, 'iti' );
rc_mask = find( rc.labels, target_event_names );

if ( use_empty_window_criterion )
  rc_mask = bfw.find_non_empty_windows( rc.start_times, rc.stop_times, rc.labels ...
    , windows, is_empty_window, empty_window_labels, rc_mask );
end

outs = struct();
outs.gc = gc;
outs.gc_mask = gc_mask;
outs.gc_spikes = gc_spikes;
outs.gc_spike_mask = gc_spike_mask;
outs.rc = rc;
outs.rc_mask = rc_mask;

end