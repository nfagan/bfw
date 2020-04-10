function [res, deltas] = n_back(labels, ts, each, of, num, mask)

if ( nargin < 6 )
  mask = rowmask( labels );
end

assert_ispair( ts, labels );
each_I = findall_or_one( labels, each, mask );

cols = ternary( ischar(of), 1, numel(of) );
res = cell( rows(labels), cols );
deltas = nan( rows(labels), 1 );

for i = 1:numel(each_I)
  ind = each_I{i};
  subset = cellstr( labels, of, ind );
  subset_ts = ts(ind);
  assert( issorted(subset_ts) );
  
  if ( num < 0 )
    abs_num = abs( num );
    prev = subset(1:end-abs_num, :);
    adjust_num = min( abs_num, numel(ind) );
    rest = repmat( {''}, adjust_num, cols );
    tot = [ rest; prev ];
    
    prev_ts = subset_ts(1:end-abs_num);
    next_ts = subset_ts(abs_num+1:end);
    delta = next_ts - prev_ts;
    
    rest_delta = nan( adjust_num, 1 );
    tot_delta = [ rest_delta; delta ];
  else
    next = subset(num+1:end, :);
    adjust_num = min( num, numel(ind) );
    rest = repmat( {''}, adjust_num, cols );
    tot = [ next; rest ];
    
    prev_ts = subset_ts(1:end-num);
    next_ts = subset_ts(num+1:end);
    delta = prev_ts - next_ts;
    
    rest_delta = nan( adjust_num, 1 );
    tot_delta = [ delta; rest_delta ];
  end
  
  res(ind, :) = tot;
  deltas(ind) = tot_delta;
end

end