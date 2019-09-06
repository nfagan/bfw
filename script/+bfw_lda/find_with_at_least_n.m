function kept_I = find_with_at_least_n(labels, each, cats, num, mask)

if ( nargin < 4 )
  mask = rowmask( labels );
end

I = findall( labels, each, mask );
C = combs( labels, cats, mask );

to_keep = true( size(I) );

for i = 1:numel(I)  
  for j = 1:size(C, 2)
    ind = find( labels, C(:, j), I{i} );
    
    if ( numel(ind) < num )
      to_keep(i) = false;
      break;
    end
  end
end

kept_I = vertcat( I{to_keep} );

end