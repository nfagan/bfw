function debug_acorr_preprocessing(spike_ts, freq_window, deg_thresh)

fc = 1e3;
acorr_w = bfw_osc.acorr_w( freq_window(1), fc );
acorr_W = acorr_w * 2;

corr_result = bfw_osc.acorr( spike_ts, acorr_w );

acorr = corr_result.plot;
bin_centers = corr_result.bincenters;

%%

sz = acorr_w + 1;
assert( mod(sz, 2) == 1 );  % must be odd

slow_sigma = bfw_osc.acorr_slow_sigma( freq_window(1), fc );
fast_sigma = bfw_osc.acorr_fast_sigma( freq_window(2), fc );

fast_filt = fspecial( 'gaussian', [1, sz], fast_sigma );
slow_filt = fspecial( 'gaussian', [1, sz], slow_sigma );

fast_smoothed = conv( acorr, fast_filt, 'same' );
slow_smoothed = conv( acorr, slow_filt, 'same' );

fast_peak_start = bfw_osc.find_fast_peak_start( bin_centers, fast_smoothed, deg_thresh, acorr_W );
fast_peak_end = abs( fast_peak_start );

peak_start_ind = find( bin_centers == fast_peak_start );
peak_end_ind = find( bin_centers == fast_peak_end );

fast_no_peak = fast_smoothed;
fast_no_peak(peak_start_ind:peak_end_ind) = fast_no_peak(peak_start_ind);

%%
figure(1); 
clf();

bin_centers = corr_result.bincenters;

hold off;
plot( bin_centers, acorr, 'linewidth', 1.5 );
hold on;
plot( bin_centers, fast_smoothed, 'r', 'linewidth', 0.75 ); 
plot( bin_centers, slow_smoothed, 'g', 'linewidth', 0.75 );

xlim( [-200, 200] );
ylim( [0, 0.2] );

shared_utils.plot.add_vertical_lines( gca, [fast_peak_start, fast_peak_end] );

plot( bin_centers, fast_no_peak, 'y', 'linewidth', 2 );

%%

figure(2);
clf();
plot( periodogram(fast_no_peak, [], 0:100, 1e3) );
hold on;
shared_utils.plot.add_vertical_lines( gca, freq_window );

end