function [parsed, c] = parse_prefixed(labels, cat)

c = combs( labels, cat );
parsed = fcat.parse( c, sprintf('%s__', cat) );

end