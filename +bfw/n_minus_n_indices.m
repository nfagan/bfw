function [curr, prev] = n_minus_n_indices(I, n_back)

curr = cell( size(I) );
prev = cell( size(curr) );

for i = 1:numel(I)
  ind = I{i};
  if ( numel(ind) > n_back )
    curr{i} = ind(n_back+1:end);
    prev{i} = ind(1:end-n_back);
  end
end

end