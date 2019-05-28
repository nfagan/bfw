function g = gauss1d(t, sigma)

ss = sigma * sigma;

exp_expr = exp( -(t.^2 ./ (2*ss)) );
denom = sigma * sqrt( 2*pi );
g = (1/denom) .* exp_expr;

end