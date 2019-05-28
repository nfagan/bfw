spike_file = bfw.load1( 'spikes' );
%%
% Index of unit with most spikes.
[~, use_unit] = max( arrayfun(@(x) numel(x.times), spike_file.data) );

unit = spike_file.data(use_unit);
%%

% high_gamma: [70, 90];

freq_window = [ 15, 25 ];
spike_ts = unit.times(1:1e4);
% spike_ts = unit.times;

bfw_osc.debug_acorr_preprocessing( spike_ts, freq_window, 10 );

%%

freq_window = [ 15, 25 ];
all_smoothed = [];
deg_thresh = 10;

for i = 1:numel(spike_file.data)
  unit_times = spike_file.data(i).times;
  max_use = min( numel(unit_times), 1e3 );
  spike_ts = unit_times(1:max_use);
  
  [bin_centers, fast_smoothed] = ...
    bfw_osc.fast_peakless_acorr( spike_ts, freq_window, deg_thresh );  
  [f, psd] = bfw_osc.acorr_psd( fast_smoothed );
  [f_osc, osc_score] = bfw_osc.osc_score( f, psd, freq_window );
  
  all_smoothed = [ all_smoothed; fast_smoothed ];
end
%%

plot( bin_centers, all_smoothed );

%%

spikes_events = bfw_osc.gather_spikes_and_events();

%%

session_I = findall( spikes_events.meta_labs, 'session', 1:10 );

acorr_outs = bfw_osc.acorr_main( spikes_events, session_I, 'freq_window', freq_window );