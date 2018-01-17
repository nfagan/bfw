function binned = bin_pulses(pulses, starts)

import shared_utils.assertions.*;

assert__isa( pulses, 'double' );
assert__isa( starts, 'double' );
assert__is_vector( pulses );
assert__is_vector( starts );

binned = cell( 1, numel(starts) );

for i = 1:numel(starts)
  if ( i < numel(starts) )
    binned{i} = pulses(pulses >= starts(i) & pulses < starts(i+1));
  else
    binned{i} = pulses(pulses >= starts(i));
  end
end

end