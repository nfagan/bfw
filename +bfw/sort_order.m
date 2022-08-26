function ord = sort_order(x, I)

validateattributes( x, {'numeric'}, {'vector', 'column'}, mfilename, 'x' );
ord = nan( size(x) );
for i = 1:numel(I)
  [~, sub_ord] = sort( x(I{i}) );
  ord(I{i}) = I{i}(sub_ord);
end

end