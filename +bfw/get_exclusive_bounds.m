function usedat = get_exclusive_bounds(usedat, uselabs, make_exclusive, spec, mask)

assert_ispair( usedat, uselabs );

if ( nargin < 5 ), mask = rowmask( uselabs ); end

I = findall( uselabs, spec, mask );

for i = 1:numel(I)    
  has_all = all( count(uselabs, make_exclusive, I{i}) > 0 );

  if ( ~has_all ), continue; end

  for j = 1:numel(make_exclusive)-1
    ind1 = find( uselabs, make_exclusive{j}, I{i} );
    ind2 = find( uselabs, make_exclusive{j+1}, I{i} );

    usedat(ind1, :) = usedat(ind1, :) & ~usedat(ind2, :);
  end
end

end