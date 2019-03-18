function out = row_mean(data, indices)

%   ROW_MEAN -- Mean across rows for subsets of data.
%
%     B = bfw.row_mean( data, I ); for real double `data` and a cell array
%     of uint64 indices `I` gives the mean across rows of `data` for each
%     array of row indices in `I`. If `data` is MxNxPxQx... then the output
%     `B` is M'xNxPxQx... where M' is the number of elements of `I`.
%
%     In other words, each row i of B is the mean across rows of data 
%     given by I{i}.
%
%     See also bfw.row_nanmean

out = bfw.mex.rowop_nd( data, indices, uint32(0) );

end