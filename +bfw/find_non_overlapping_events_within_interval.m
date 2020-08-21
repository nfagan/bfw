function inds = find_non_overlapping_events_within_interval(start_times, look_back, look_ahead, I)

validateattributes( start_times, {'double'}, {'column'}, mfilename, 'start_times' );
validateattributes( look_back, {'double'}, {'scalar'}, mfilename, 'look_back' );
validateattributes( look_ahead, {'double'}, {'scalar'}, mfilename, 'look_ahead' );

if ( nargin < 4 )
  I = { rowmask(start_times) };
end

validateattributes( I, {'cell'}, {'vector'}, mfilename, 'I' );
cellfun( @(x) validateattributes(x, {'numeric'} ...
  , {'vector'}, mfilename, 'I'), I, 'un', 0 );

inds = cell( size(I) );

for i = 1:numel(I)
  some_events = start_times(I{i});

  [evts, ind] = sort( some_events );  
  keep_inds = [];
  
  for j = 1:numel(evts)
    curr_evt = evts(j);
    
    if ( j == 1 )
      prev_evt = -inf;
    else
      prev_evt = evts(j-1);
    end
    if ( j == numel(evts) )
      next_evt = inf;
    else
      next_evt = evts(j+1);
    end
    
    if ( curr_evt - prev_evt > look_back && ...
         next_evt - curr_evt > look_ahead )
       keep_inds(end+1, 1) = j;
    end
  end
  
  kept_ind = ind(keep_inds);
  inds{i} = sort( I{i}(kept_ind) );
end

end