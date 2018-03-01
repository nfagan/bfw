function evts_b = clock_a_to_b(events_a, clock_a, clock_b)

%   CLOCK_A_TO_B -- Convert time stamps in one clock to another.
%
%     Time-stamps in `clock_a` and `clock_b` must be in the same units,
%     unless all `events_a` are within `[min(clock_a), max(clock_a)]`.
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
  
  if ( sign(offset) == 1 && closest < numel(clock_a) )
    frac_offset = offset / (clock_a(closest+1) - clock_a(closest));
    evts_b(j) = clock_b(closest) + (clock_b(closest+1) - clock_b(closest)) * frac_offset;
    continue;
  elseif ( sign(offset) == -1 && closest > 1 )
    pos_offset = clock_a(closest) + offset - clock_a(closest-1);
    frac_offset = pos_offset / (clock_a(closest) - clock_a(closest-1));
    evts_b(j) = clock_b(closest-1) + (clock_b(closest) - clock_b(closest-1)) * frac_offset;
    continue;
  end
  
  %   we get here if `evt` is before the first `clock_a`, or after the last
  %   `clock_a`.
  evts_b(j) = clock_b(closest) + offset;
end

end