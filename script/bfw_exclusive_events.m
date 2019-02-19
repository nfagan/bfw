function keep = bfw_exclusive_events(start_indices, stop_indices, labels, pairs, I)

assert_ispair( start_indices, labels );

N = numel( start_indices );
validateattributes( stop_indices, {'double'}, {'numel', N}, mfilename, 'stop_indices' );

keep = fast_method( start_indices, stop_indices, labels, pairs, I );

% keep1 = slow_method( start_indices, stop_indices, labels, pairs, I );
% keep2 = fast_method( start_indices, stop_indices, labels, pairs, I );
% 
% assert( isequal(keep1, keep2), 'Methods were not equal' );
% 
% keep = keep2;

end

function keep = fast_method(start_indices, stop_indices, labels, pairs, I)

keep = true( numel(start_indices), 1 );

for i = 1:numel(I)  
  for j = 1:numel(pairs)
    is_a = find( labels, pairs{j}{1}, I{i} );
    is_b = find( labels, pairs{j}{2}, I{i} );
    
    for k = 1:numel(is_b)
      c_is_b = is_b(k);
      
      start_b = start_indices(c_is_b);
      stop_b = stop_indices(c_is_b);
      
      start_a = start_indices(is_a);
      stop_a = stop_indices(is_a);
      
      pre_a_start =   any( start_b <= start_a & stop_b >= start_a );
      pre_a_stop =    any( start_b <= stop_a & stop_b >= stop_a );
      is_eq_start =   any( (start_b == start_a) | (start_b == stop_a) );
      is_eq_stop =    any( (stop_b == start_a) | (stop_b == stop_a) );
      within_range =  any( start_b >= start_a & stop_b <= stop_a );
      
      overlaps_with_a = pre_a_start || pre_a_stop || is_eq_start || is_eq_stop || within_range;
      
      if ( overlaps_with_a )
        keep(c_is_b) = false;
      end
    end
  end
end

keep = find( keep );

end

function keep = slow_method(start_indices, stop_indices, labels, pairs, I)

keep = true( numel(start_indices), 1 );

for i = 1:numel(I)  
  shared_utils.general.progress( i, numel(I) );
  
  for j = 1:numel(pairs)
    is_a = find( labels, pairs{j}{1}, I{i} );
    is_b = find( labels, pairs{j}{2}, I{i} );
    
    range_a = arrayfun( @(x, y) x:y, start_indices(is_a), stop_indices(is_a), 'un', 0 );
    
    for k = 1:numel(is_b)
      c_is_b = is_b(k);
      
      start_b = start_indices(c_is_b);
      stop_b = stop_indices(c_is_b);
      
      range_b = start_b:stop_b;
      overlaps_with_a = cellfun( @(x) ~isempty(intersect(x, range_b)), range_a );
      
      if ( any(overlaps_with_a) )
        keep(c_is_b) = false;
      end
    end
  end
end

keep = find( keep );


end