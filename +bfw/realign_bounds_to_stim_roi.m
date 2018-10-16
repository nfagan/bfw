function [newdat, newlabs] = realign_bounds_to_stim_roi(dat, labs, is_ib_t0, spec, mask)

assert_ispair( dat, labs );

if ( nargin < 5 ), mask = rowmask( labs ); end

I = findall( labs, spec, mask );

newinds = [];
newlabs = fcat();
stp = 1;

for i = 1:numel(I)
  shared_utils.general.progress( i, numel(I) );
  
  [roi_I, roi_C] = findall( labs, 'roi', I{i} );
  c = combvec( 1:numel(roi_I), 1:numel(roi_I) );
  
  for j = 1:size(c, 2)
    inds = c(:, j);
    
    stim_roi_name = roi_C{inds(1)};
    bounds_roi_name = roi_C{inds(2)};
    
    stim_roi_ind = roi_I{inds(1)};
    bounds_roi_ind = roi_I{inds(2)};
    
    subset_ib_t0 = is_ib_t0(stim_roi_ind);    
    
    assert( numel(subset_ib_t0) == numel(bounds_roi_ind) );
    
    ib_stim_lab = sprintf( 'stim_on_%s', stim_roi_name );
    oob_stim_lab = sprintf( 'stim_on_not_%s', stim_roi_name );
    bounds_lab = sprintf( 'in_bounds_%s', bounds_roi_name );
    
    append( newlabs, labs, bounds_roi_ind );
    
    for k = 1:numel(bounds_roi_ind)
      if ( subset_ib_t0(k) )
        setcat( newlabs, 'stim_roi', ib_stim_lab, stp );
        setcat( newlabs, 'stim_oob', 'stim on in bounds', stp );
      else
        setcat( newlabs, 'stim_roi', oob_stim_lab, stp );
        setcat( newlabs, 'stim_oob', 'stim on out of bounds', stp );
      end
      
      setcat( newlabs, 'roi', bounds_lab, stp );
      
      newinds = [ newinds; bounds_roi_ind(k) ];
      
      stp = stp + 1;
    end
  end
end

newdat = dat(newinds, :);

end