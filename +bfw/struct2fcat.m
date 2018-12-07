function f = struct2fcat(x)

validateattributes( x, {'struct'}, {'nonempty'}, mfilename );

if ( numel(x) == 1 )
  f = fcat.from( struct2cell(x)', fieldnames(x) );
else
  c = struct2cell( x );
  cats = fieldnames( x );
  
  f = fcat.with( cats, numel(x) );
  
  for i = 1:numel(x)
    setcat( f, cats, c(:, :, i), i );
  end
  
  prune( f );
end

end