conf = bfw.config.load();

sorted_events = shared_utils.io.fload( fullfile(bfw.dataroot(conf) ...
  , 'analyses/events/sorted_events.mat') );

%%

spike_data = bfw_gather_spikes( ...
  'config', conf ...
  , 'spike_subdir', 'cc_spikes' ...
  , 'is_parallel', true ...
);

bfw.add_monk_labels( spike_data.labels );

%%

[processed_spikes, processed_events] = bfw_prepare_acc_bla_subset( spike_data, sorted_events );

%%

save( fullfile(bfw.dataroot(conf), 'public', 'otnal_supp_data_analysis', 'spike_event_data.mat') ...
  , 'processed_spikes', 'processed_events' );

%%

evt_session_index = ismember( processed_events.labels.categories, 'session' );
evt_sessions = processed_events.labels.labels(:, evt_session_index);
unique_evt_sessions = unique( evt_sessions );

spike_session_index = ismember( processed_spikes.labels.categories, 'session' );
spike_sessions = processed_spikes.labels.labels(:, spike_session_index);

for i = 1:numel(unique_evt_sessions)
  cells_this_session = spike_sessions == unique_evt_sessions(i);
  
  
end