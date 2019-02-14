function keep = bfw_exclusive_events(start_indices, stop_indices, labels, pairs, I)

assert_ispair( start_indices, labels );

validateattributes( stop_indices, {'double'}, {'vector', 'numel' ...
  , numel(start_indices)}, mfilename, 'stop_indices' );

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