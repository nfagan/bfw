analysis_subdir = fullfile( bfw.dataroot(), 'analyses', 'spike_osc' );

spike_filename = fullfile( analysis_subdir, 'spikes_events.mat' );
spikes_events = shared_utils.io.fload( spike_filename );

%%

freq_window = [ 15, 25 ];
output_subdir = 'first';

session_mask = rowmask( spikes_events.meta_labs );
session_I = findall( spikes_events.meta_labs, 'session', session_mask );

acorr_outs = bfw_osc.acorr_main( spikes_events, session_I, 'freq_window', freq_window );

acorr_filename = fullfile( analysis_subdir, output_subdir, 'acorr_outs.mat' );
save( acorr_filename, acorr_outs, '-v7.3' );