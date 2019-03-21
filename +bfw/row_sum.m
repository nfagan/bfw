function out = row_sum(data, indices)

%   ROW_SUM -- Sum across rows for subsets of data.
%
%     B = bfw.row_sum( data, I ); for real double `data` and a cell array
%     of uint64 indices `I` gives the sum across rows of `data` for each
%     array of row indices in `I`. If `data` is MxNxPxQx... then the output
%     `B` is M'xNxPxQx... where M' is the number of elements of `I`.
%
%     In other words, each row i of B is the sum across rows of data 
%     given by I{i}.
%
%     See also bfw.row_mean, bfw.mex.rowop_nd

if ( numel(indices) > 0 && isa(indices{1}, 'double') )
  indices = cellfun( @uint64, indices, 'un', 0 );
end

out = bfw.mex.rowop_nd( data, indices, uint32(2) );

end