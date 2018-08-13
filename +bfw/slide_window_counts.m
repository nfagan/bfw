function [counts, bin_starts] = slide_window_counts(events, all_events, bin_width, step_size, look_back, look_ahead)

bin_starts = look_back:step_size:look_ahead;
bin_stops = bin_starts + bin_width;

counts = zeros( numel(bin_starts), 1 );
    
for i = 1:numel(events)
  evt = events(i);

  current_bin_starts = bin_starts + evt;
  current_bin_stops = bin_stops + evt;
  
  for j = 1:numel(all_events)
    ind = all_events(j) >= current_bin_starts & all_events(j) < current_bin_stops;
    
    counts = counts + ind(:);
  end
end

end