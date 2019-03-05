function nearest_indices = find_nearest(t, b)

%   FIND_NEAREST -- Find indices of elements of sorted array A closest to B.
%
%     I = ... find_nearest( A, B ) for column vectors A and B returns 
%     an array the same size as B containing indices of the elements of A
%     closest to each B. That is, the i-th element in I gives the index
%     into A such that abs(A(I(i)) - B(i)) is as small as possible for the
%     given A. A must be sorted in ascending order. I is of class int64.
%
%     See also bfw.mex.find_nearest_sorted

assert( issorted(t, 'ascend'), 'First input must be sorted in ascending order.' );

% first sorted index gives: sorted_b = b(sorted_index_a2b)
[sorted_b, sorted_index_a2b] = sort( b, 'ascend' );

% sorting this index gives: b = sorted_b(sorted_index_b2a)
[~, sorted_index_b2a] = sort( sorted_index_a2b, 'ascend' );

nearest_indices = bfw.mex.find_nearest_sorted( t, sorted_b, false );
nearest_indices = nearest_indices(sorted_index_b2a);

end