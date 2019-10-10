function to_keep = find_significant_unit_info(labels, unit_info, mask)

if ( nargin < 3 )
  mask = rowmask( labels );
end

to_keep = bfw_ct.mask_significant_unit_info( labels, unit_info, mask, @find );

end