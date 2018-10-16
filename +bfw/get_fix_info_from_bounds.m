function [nfix, durations] = get_fix_info_from_bounds(fixdat, t)

assert( size(fixdat, 2) == numel(t), 'Bounds data do not correspond to given time vector.' );

nfix = rowzeros( rows(fixdat) );
durations = rowzeros( rows(fixdat) );

for i = 1:rows(fixdat)
  [starts, durs] = shared_utils.logical.find_all_starts( fixdat(i, :) );
  
  tot_dur = 0;
  
  for j = 1:numel(starts)
    start = starts(j);
    stop = start + durs(j) - 1;
    
    tot_dur = tot_dur + t(stop) - t(start);
  end
  
  nfix(i) = numel( starts );
  durations(i) = tot_dur;
end

end