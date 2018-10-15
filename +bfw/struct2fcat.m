function f = struct2fcat(x)

validateattributes( x, {'struct'}, {'scalar'}, mfilename );

f = fcat.from( struct2cell(x)', fieldnames(x) );

end