function [rc, params] = make_reward_component(reward_counts, varargin)

default_event_names = { 'cs_target_acquire', 'cs_reward', 'cs_delay', 'iti' };

defaults = struct();
defaults.event_names = default_event_names;
defaults.normalize_reward_counts = false;
defaults.time_windows = cellfun( @bfw_lda.default_time_window_for_reward_event, default_event_names, 'un', 0 );

params = bfw.parsestruct( defaults, varargin );

normalize_reward_counts = params.normalize_reward_counts;
event_names = params.event_names;

rc_time_windows = params.time_windows;

rc = reward_counts;
[rc_psth, label_inds] = bfw_lda.time_average_subsets( rc.psth, rc.labels, rc.t, event_names, rc_time_windows );

if ( normalize_reward_counts )
  error( 'Normalization not yet supported with time windows.' );
  rc_psth = bfw_lda.normalize_subsets( rc_psth, rc.labels, event_names, 'iti' );
end

rc.psth = rc_psth;
rc.data_type = 'spikes';
bfw.unify_single_region_labels( rc.labels );

start_times = nan( rows(rc_psth), 1 );
stop_times = nan( size(start_times) );

for i = 1:numel(label_inds)
  subset_events = reward_counts.event_times(label_inds{i});
  
  start_times(label_inds{i}) = subset_events + params.time_windows{i}(1);
  stop_times(label_inds{i}) = subset_events + params.time_windows{i}(2);
end

rc.start_times = start_times;
rc.stop_times = stop_times;

end