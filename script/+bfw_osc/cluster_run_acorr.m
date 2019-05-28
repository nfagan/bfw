analysis_path = fullfile( bfw.dataroot(), 'analyses', 'spike_osc' );

spike_filename = fullfile( analysis_path, 'spikes_events.mat' );
spikes_events = shared_utils.io.fload( spike_filename );

%%

freq_windows = { [15, 25], [45, 70] };
freq_roi_names = { 'beta', 'gamma' };

assert( numel(freq_windows) == numel(freq_roi_names) );

session_mask = rowmask( spikes_events.meta_labs );
session_I = findall( spikes_events.meta_labs, 'session', session_mask );

for i = 1:numel(freq_windows)
  freq_window = freq_windows{i};
  output_subdir = freq_roi_names{i};

  acorr_outs = bfw_osc.acorr_main( spikes_events, session_I, 'freq_window', freq_window );

  acorr_path = fullfile( analysis_path, output_subdir );
  shared_utils.io.require_dir( acorr_path );

  acorr_filename = fullfile( acorr_path, 'acorr_outs.mat' );
  save( acorr_filename, 'acorr_outs', '-v7.3' );
end