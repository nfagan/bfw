function s = acorr_fast_sigma(fmax, fc)

s = min( 2, 134/(1.5*fmax) ) * (fc/1e3);

end