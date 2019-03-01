function varargout = find_nearest_sorted(varargin)

%   FIND_NEAREST_SORTED -- Find indices of elements of A closest to B, when
%     both A and B are sorted arrays.
%
%     I = ... find_nearest_sorted( A, B ) for column vectors A and B returns 
%     an array the same size as B containing indices of the elements of A
%     closest to each B. That is, the i-th element in I gives the index
%     into A such that abs(A(I(i)) - B(i)) is as small as possible for the
%     given A. A and B must be sorted in ascending order. I is of class
%     int64.
%
%     I = ... find_nearest_sorted( ..., CONFIRM_IS_SORTED ) for the logical
%     scalar flag CONFIRM_IS_SORTED indicates whether to check that arrays
%     A and B are sorted in ascending order, and issue an error message if
%     they are not. Default is true.
%
%     If A contains duplicate elements for which there could be multiple 
%     absolute minima for a given element of B, the associated index is the 
%     index of the last such element in A. More concretely,
%     bfw.mex.find_nearest_sorted( [1, 1, 1, 1], 1 ) returns 4.
%
%     NaN elements in B are assigned the index 1 in I. NaN elements in A
%     are skipped. If all elements of A are NaN, all indices in I are 1.
%
%     EX //
%
%     I = bfw.mex.find_nearest_sorted( 1:5, [1.1, 2.2, 2.8, 3.2] )
%
%     See also bfw.make.help

error( 'No find_nearest_sorted mex function exists for your platform: "%s".', computer );

end