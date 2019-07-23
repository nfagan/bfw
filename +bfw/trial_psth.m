function [psth, bin_t] = trial_psth(spikes, events, min_t, max_t, bin_width)

%   TRIAL_PSTH -- Bin spike counts aligned to events, preserving each trial.
%
%     psth = bfw.trial_psth( spikes, events, min_t, max_t, bin_width );
%     returns an MxN matrix of M-trials by N-time bins of `bin_width`
%     size, each containing the number of `spikes` times that fall in that 
%     time bin. The i-th row of `psth` is the timecourse of binned spike
%     counts aligned to the i-th element of `events`; `min_t` gives the 
%     amount of time to look back before each event, and `max_t` the 
%     amount of time to look ahead. 
%
%     Units of `spikes`, `events`, `min_t`, `max_t`, and `bin_width` must
%     be consistent -- e.g., they can all be in milliseconds, or all in 
%     seconds.
%
%     [..., bin_t] = trial_psth(...) also returns a vector of time-stamps
%     for each bin / column of `psth`. Note that each element of `bin_t` 
%     corresponds to the start, rather than the middle, of a bin.
%
%     See also histc

validateattributes( spikes, {'double', 'single'}, {'column'}, mfilename, 'spikes' );
validateattributes( events, {'double', 'single'}, {'column'}, mfilename, 'events' );

aligned_ts = bsxfun( @minus, spikes, events' );
bin_t = min_t:bin_width:max_t;

psth = histc( aligned_ts, bin_t, 1 )';

psth = psth(:, 1:end-1);
bin_t = bin_t(1:end-1);

end