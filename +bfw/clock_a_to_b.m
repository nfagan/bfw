function evts_b = clock_a_to_b(events_a, clock_a, clock_b)

%   CLOCK_A_TO_B -- Convert time stamps in one clock to another.
%
%     IN:
%       - `events_a` (double) -- Vector of time-stamps to convert.
%       - `clock_a` (double) -- Vector of time-stamps in terms of `a`.
%       - `clock_b` (double) -- Vector of time-stamps in terms of `b`. Each
%         element (i) of `b` is assumed to correspond to the time (i) in
%         `a`.
%     OUT:
%       - `evts_b` (double)

evts_b = zeros( size(events_a) );

assert( numel(clock_a) == numel(clock_b), ['Number of clock samples in `A`' ...
  , ' must number of clock samples in `B`.'] );

for j = 1:numel(events_a)
  evt = events_a(j);
  [~, closest] = min( abs(clock_a-evt) );
  offset = evt - clock_a(closest);
  evts_b(j) = clock_b(closest) + offset;
end

end