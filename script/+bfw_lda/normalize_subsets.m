function out_data = normalize_subsets(data, labels, targ_selectors, base_selectors, mask)

validateattributes( targ_selectors, {'cell'}, {}, mfilename, 'target selectors' );

assert_ispair( data, labels );

if ( nargin < 5 )
  mask = rowmask( labels );
end

base_ind = find( labels, base_selectors, mask );
out_data = nan( size(data) );

for i = 1:numel(targ_selectors)
  targ_ind = find( labels, targ_selectors{i}, mask );
  
  if ( numel(targ_ind) ~= numel(base_ind) )
    error( 'Target and baseline subsets mismatch.' );
  end
  
  out_data(targ_ind, :) = data(targ_ind, :) - nanmean( data(base_ind, :), 2 );
end

end