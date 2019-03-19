function varargout = rowop_nd(varargin)

%   ROWOP_ND -- Apply function to indexed subsets of rows of N-dimensional data.
%
%     B = bfw.mex.rowop_nd( data, I, function_type )
%
%     for real double `data` and a cell array of uint64 indices `I` 
%     applies a function given by the uint32 scalar `function_type` to 
%     subsets of rows of data identified by each uint64 index array in `I`. 
%     If `data` is MxNxPxQx... then the output `B` is M'xNxPxQx... where 
%     M' is the number of elements of `I`. 
%
%     In other words, each row i of B is the result of applying a function 
%     to rows of data given by I{i}.
%
%     `function_type` is one of:
%       - uint32(0): Mean across rows of data.
%       - uint32(1): Mean across rows of data, excluding NaN values.
%       - uint32(2): Sum across rows of data.
%
%     B = bfw.mex.rowop_nd( ..., thread_type ) controls the use of threads
%     by the function.
%
%     `thread_type` is one of:
%       - uint32(0): Auto (default). Use threads if the number of elements 
%         of `I` is at least as large as the number of concurrent threads 
%         supported by your system.
%       - uint32(1): Use a single thread.
%
%     version_identifier = bfw.mex.rowop_nd(), with no input arguments, 
%     returns a char vector giving a version id for the mex file.
%
%     This function will tend to be more efficient than an equivalent
%     routine in Matlab as the number of indices increases.
%
%     EX //
%
%     f = fcat.example();
%     data = fcat.example( 'smalldata' );
%
%     % Take an average across each session x dose x monkey
%     I = findall( f, {'session', 'dose', 'monkey'} );
%     meaned = bfw.mex.rowop_nd( data, I, uint32(0) );
%
%     See also bfw.row_mean

end