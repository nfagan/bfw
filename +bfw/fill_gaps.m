function [tf, events] = fill_gaps(tf, events, threshold)

%   FILL_GAPS -- Fill-gaps between starts of true samples.
%
%     [tf, events] = ... fill_gaps( tf, events, threshold ) merges the
%     indices given by `events` that are within `threshold` distance of
%     each other. Values of `tf` are set to true between the merged events.
%
%     IN:
%       - `tf` (logical)
%       - `events` (double)
%       - `threshold` (double)
%     OUT:
%       - `tf` (logical)
%       - `events` (double)

ind = [ diff(events) <= threshold, false ];

if ( ~any(ind) ), return; end

num_inds = find( ind );

to_keep_evts = true( size(events) );

for i = 1:numel(num_inds)
  start_ind = events(num_inds(i));
  stop_ind = events(num_inds(i)+1);
  to_keep_evts(num_inds(i)+1) = false;
  tf(start_ind:stop_ind) = true;
end

events = events(to_keep_evts);

[tf, events] = bfw.fill_gaps( tf, events, threshold );

end