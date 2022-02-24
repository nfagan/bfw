function I = find_combinations(f, C, varargin)

I = cell( size(C, 2), 1 );
for i = 1:numel(I)
  I{i} = find( f, C(:, i), varargin{:} );
end

end