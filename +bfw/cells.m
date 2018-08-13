function varargout = cells(varargin)

s = cell( varargin{:} );

N = nargout;

varargout = cellfun( @(x) s, cell(1, N), 'un', 0 );

end