function pos = interpolate_nans( pos, max_samples )

shared_utils.assertions.assert__isa( pos, 'double' );
shared_utils.assertions.assert__isa( max_samples, 'double' );
shared_utils.assertions.assert__is_scalar( max_samples );

nans = isnan( pos );

for i = 1:size(nans, 1)
  [nan_seqs, nan_seq_l] = shared_utils.logical.find_all_starts( nans(i, :) );
  p = pos(i, :);
  
  within_thresh = nan_seq_l <= max_samples;
  
  for j = 2:numel(nan_seqs)-1
    
    if ( ~within_thresh(j-1) || ~within_thresh(j) || ~within_thresh(j+1) )
      continue;
    end
    
    ind = nan_seqs(j);
    ind_pre = ind;
    ind_post = ind;
    
    exit_pre = false;
    exit_post = false;
    
    while ( isnan(p(ind_pre)) )
      ind_pre = ind_pre - 1;
      if ( ind_pre < 1 ), exit_pre = true; break; end
    end
    
    while ( isnan(p(ind_post)) )
      ind_post = ind_post + 1;
      if ( ind_post > numel(p) ), exit_post = true; break; end
    end
    
    if ( exit_pre || exit_post ), continue; end
    
    prev = p( ind_pre );
    post = p( ind_post );
    
    assert( ind - ind_pre <= max_samples * 2 );
    assert( ind_post - ind <= max_samples * 2 );
    
    pos(i, nan_seqs(j)) = mean( [prev, post] );
    
  end
end

end