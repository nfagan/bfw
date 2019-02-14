function pairs = bfw_assert_non_overlapping(start_indices, stop_indices, I, mask)

pairs = {};

for i = 1:numel(I)
  shared_utils.general.progress( i, numel(I) );
  
  current_I = intersect( I{i}, mask );
  
  starts = start_indices(current_I);
  stops = stop_indices(current_I);
  
  for j = 1:numel(starts)
    range1 = starts(j):stops(j);
    
    for k = 1:numel(starts)
      if ( j == k ), continue; end
      
      range2 = starts(k):stops(k);

      if ( ~isempty(intersect(range1, range2)) )
        pairs{end+1} = [ current_I(j), current_I(k) ];
      end
    end
  end
end

pairs = vertcat( pairs{:} );

end