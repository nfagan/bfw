function [parsed, c] = parse_prefixed(labels, cat, varargin)

c = combs( labels, cat, varargin{:} );
parsed = fcat.parse( c, sprintf('%s__', cat) );

end