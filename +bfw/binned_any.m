function [out, ind] = binned_any( vec, window_size )

import shared_utils.assertions.*;

shared_utils.assertions.assert__is_vector( vec );

start = 1;
stop = start + window_size - 1;
N = numel( vec );
stp = 1;

out = false( 1, floor(N / window_size) );
ind = zeros( size(out) );

while ( stop <= N )
  ind(stp) = start;
  out(stp) = any( vec(start:stop) );
  start = start + window_size;
  stop = start + window_size - 1;
  stp = stp + 1;
end

end