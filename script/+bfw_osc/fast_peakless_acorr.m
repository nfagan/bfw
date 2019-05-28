function [bin_centers, fast_smoothed] = fast_peakless_acorr(spike_ts, freq_window, peak_deg_thresh)

fc = 1e3;
acorr_w = bfw_osc.acorr_w( freq_window(1), fc );
acorr_W = acorr_w * 2;

%%
corr_result = bfw_osc.acorr( spike_ts, acorr_w );
%%

acorr = corr_result.plot;
bin_centers = corr_result.bincenters;

fast_sigma = bfw_osc.acorr_fast_sigma( freq_window(2), fc );
fast_smoothed = bfw_osc.filter_acorr( acorr, acorr_w, fast_sigma );

fast_peak_start = bfw_osc.find_fast_peak_start( bin_centers, fast_smoothed, peak_deg_thresh, acorr_W );
fast_peak_end = abs( fast_peak_start );

peak_start_ind = find( bin_centers == fast_peak_start );
peak_end_ind = find( bin_centers == fast_peak_end );

% Remove peak.
fast_smoothed(peak_start_ind:peak_end_ind) = fast_smoothed(peak_start_ind);

end