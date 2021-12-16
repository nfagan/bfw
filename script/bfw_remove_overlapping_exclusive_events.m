function e_keep = bfw_remove_overlapping_exclusive_events(i_start_stop, i_labels, i_mask, e_start_stop, e_labels, e_mask, each)

assert_ispair( i_start_stop, i_labels );
assert_ispair( e_start_stop, e_labels );

[e_each_i, e_each_c] = findall( e_labels, each, e_mask );
keep = true( size(e_start_stop, 1), 1 );

for i = 1:numel(e_each_i)
  shared_utils.general.progress( i, numel(e_each_i) );
  
  e_ind = e_each_i{i};
  i_ind = find( i_labels, e_each_c(:, i), i_mask );
  
  i_se = i_start_stop(i_ind, :);
  e_se = e_start_stop(e_ind, :);
  
  i0 = i_se(:, 1);
  i1 = i_se(:, 2);
  
  for j = 1:size(e_se, 1)
    e0 = e_se(j, 1);
    e1 = e_se(j, 2);
    isect = arrayfun( @(x, y) isect1d(x, y, e0, e1), i0, i1 );
    
    if ( ~isnan(e0) && ~isnan(e1) && any(isect) )
      keep(e_ind(j)) = false;
    end
  end
end

e_keep = intersect( find(keep), e_mask );

end

function tf = isect1d(a0, a1, b0, b1)

if ( a0 < b0 )
  tf = a1 >= b0;
else
  tf = b1 >= a0;
end

end