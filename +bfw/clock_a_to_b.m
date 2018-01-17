function evts_b = clock_a_to_b(events_a, clock_a, clock_b)

evts_b = zeros( size(events_a) );

for j = 1:numel(events_a)
  evt = events_a(j);
  [~, closest] = min( abs(clock_a-evt) );
  offset = evt - clock_a(closest);
  evts_b(j) = clock_b(closest) + offset;
end

end