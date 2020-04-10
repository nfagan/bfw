function labels = add_monk_pair_labels(labels, num_prefix)

if ( nargin < 2 )
  num_prefix = 3;
end

c_m1s = combs( labels, 'id_m1' );
c_m2s = combs( labels, 'id_m2' );

m1s = eachcell( @(x) strip_prefix(x, num_prefix), c_m1s );
m2s = eachcell( @(x) strip_prefix(x, num_prefix), c_m2s );

pair_inds = dsp3.numel_combvec( m1s, m2s );

for i = 1:size(pair_inds, 2)
  p_ind = pair_inds(:, i);
  m1 = c_m1s(p_ind(1));
  m2 = c_m2s(p_ind(2));
  
  m1_ = m1s{p_ind(1)};
  m2_ = m2s{p_ind(2)};
  
  ind = find( labels, [m1, m2] );
  set_str = sprintf( '%s_%s', m1_, m2_ );
  
  addsetcat( labels, 'm1_m2', set_str, ind );
end

end

function x = strip_prefix(x, num)

num = min( num, numel(x) );
x(1:num) = [];

end