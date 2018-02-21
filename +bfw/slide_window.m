function [out, out_t] = slide_window( bounds, t, window_size, step_size )

total = floor( numel(bounds) / step_size );

N = numel( bounds );

out = false( 1, total );
out_t = zeros( 1, total );

half_window = floor( window_size/2 );
start = 1;
stp = 1;
stop = min( N, start+window_size );

while ( stop <= N )
  out(stp) = any( bounds(start:stop-1) );
  out_t(stp) = t(start+half_window);
  stp = stp + 1;
  start = start + step_size;
  stop = start + window_size;
end

end