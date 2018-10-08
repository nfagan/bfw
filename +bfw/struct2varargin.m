function out = struct2varargin(s)

%   STRUCT2VARARGIN -- Convert struct to array of 'name', value pairs.
%
%     IN:
%       - `s` (struct)
%     OUT:
%       - `out` (cell)

validateattributes( s, {'struct'}, {'scalar'}, 'struct2varargin' );

values = struct2cell( s );
fs = fieldnames( s );

out = cell( 1, numel(values) * 2 );

out(1:2:end) = fs;
out(2:2:end) = values;

end