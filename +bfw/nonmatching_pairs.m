function inds = nonmatching_pairs(a, b)

inds = dsp3.numel_combvec( a, b );
keep = true( size(inds, 2), 1 );
for i = 1:size(inds, 2)
  ind = inds(:, i);
  if ( strcmp(a(ind(1)), b(ind(2))) )
    keep(i) = false;
  end
end

inds = inds(:, keep);

end