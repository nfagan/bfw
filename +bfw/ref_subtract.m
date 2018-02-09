function rest = ref_subtract( cont )

import shared_utils.assertions.*;

assert__isa( cont, 'Container' );
assert( cont.contains('ref'), 'reb_subtract: No "ref" region present.' );

ref = cont({'ref'});
rest = rm( cont, 'ref' );

[I, C] = rest.get_indices( {'region', 'channel'} );

for i = 1:numel(I)
  index = I{i};
  subset_rest = rest(index);
  subbed = subset_rest - ref;
  rest.data(index, :) = subbed.data;
end


end