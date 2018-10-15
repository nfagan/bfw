function [indices, labels] = get_stim_roi_info(is_ib_t0, labs, stim_spec, mask)

if ( nargin < 4 ), mask = rowmask( labs ); end
assert_ispair( is_ib_t0, labs );

I = findall( labs, stim_spec, mask );

stim_ib_labs = fcat();
stim_ib_indices = uint64([]);

for i = 1:numel(I)
  ind = I{i};
  
  ib_inds = ind(is_ib_t0(ind));
  
  append1( stim_ib_labs, labs, ind, numel(ib_inds) );
  stim_ib_indices = [ stim_ib_indices; ib_inds ];
end

oob = setdiff( stim_ib_indices, mask );
assert_ispair( stim_ib_indices, stim_ib_labs );

end