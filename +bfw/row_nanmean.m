function out = row_nanmean(data, indices)

%   ROW_NANMEAN -- Mean across rows for subsets of data, excluding NaN.
%
%     B = bfw.row_nanmean( data, I ); for real double `data` and a cell array
%     of uint64 indices `I` gives the mean across rows of `data` for each
%     array of row indices in `I`, excluding NaN values. If `data` is 
%     MxNxPxQx... then the output `B` is M'xNxPxQx... where M' is the number 
%     of elements of `I`.
%
%     In other words, each row i of B is the mean across rows of data 
%     given by I{i}, excluding NaN values.
%
%     See also bfw.row_mean

out = bfw.mex.rowop_nd( data, indices, uint32(1) );

end