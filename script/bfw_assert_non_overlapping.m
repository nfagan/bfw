function pairs = bfw_assert_non_overlapping(start_indices, stop_indices, I, mask)

pairs = [];

for i = 1:numel(I)
  current_I = intersect( I{i}, mask );
  
  starts = start_indices(current_I);
  stops = stop_indices(current_I);
  
  for j = 1:numel(starts)
    for k = 1:numel(starts)
      if ( j == k ), continue; end
      
      condition1 = starts(k) >= starts(j) & stops(j) <= stops(k);
      condition2 = starts(j) >= starts(k) & stops(k) <= stops(j);
      
      if ( condition1 || condition2 )
        pairs(end+1, :) = [ current_I(j), current_I(k) ];
      end
    end
  end
end

end