function filtered = filter_acorr(acorr, acorr_w, sigma)

sz = acorr_w + 1;
assert( mod(sz, 2) == 1 );  % must be odd

filt = fspecial( 'gaussian', [1, sz], sigma );
filtered = conv( acorr, filt, 'same' );

end