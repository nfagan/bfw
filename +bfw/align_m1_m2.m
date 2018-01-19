function [aligned_data, t] = align_m1_m2( m1_data, m2_data, m1_times, m2_times, sync_m1, sync_m2, fs, N )

import shared_utils.assertions.*;

assert__isa( m1_data, 'double' );
assert__isa( m2_data, 'double' );
assert__isa( m1_times, 'double' );
assert__isa( m2_times, 'double' );
assert__isa( sync_m1, 'double' );
assert__isa( sync_m2, 'double' );
assert( numel(sync_m1) == numel(sync_m2), 'Sync times must match for m1 and m2.' );
assert__isa( fs, 'double' );
assert__isa( N, 'double' );
assert__is_scalar( fs );
assert__is_scalar( N );

t = 0:fs:N;

sz_m1 = size( m1_data, 1 );
sz_m2 = size( m2_data, 1 );

aligned_data = nan( sz_m1 + sz_m2, numel(t) );

in_t_b_m1 = m1_times > sync_m1(1);
in_t_b_m2 = m2_times > sync_m2(1);

m1_times = m1_times(in_t_b_m1);
m2_times = m2_times(in_t_b_m2);

m1_data = m1_data(:, in_t_b_m1);
m2_data = m2_data(:, in_t_b_m2);

aligned_m1t = bfw.clock_a_to_b( m1_times, sync_m1, sync_m2 );

for j = 1:numel(aligned_m1t)
  [~, nearest_1ms] = min( abs(aligned_m1t(j) - t) );
  ind = 1:sz_m1;
  aligned_data(ind, nearest_1ms) = m1_data(:, j);
end

for j = 1:numel(m2_times)
  [~, nearest_1ms] = min( abs(m2_times(j) - t) );
  ind = sz_m1+1:size(aligned_data, 1);
  aligned_data(ind, nearest_1ms) = m2_data(:, j);
end

end