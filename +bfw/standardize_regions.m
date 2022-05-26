function l = standardize_regions(l)

is_char = ischar( l );
l = cellstr( l );
l = lower( l );
accg = strcmp( l, 'accg' );
l(accg) = { 'acc' };

if ( is_char )
  l = char(l);
end

end