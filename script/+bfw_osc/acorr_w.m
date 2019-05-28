function w = acorr_window(fmin, fc)

% The Oscillation Score: An Efficient Method for Estimating Oscillation 
% Strength in Neuronal Activity. 

crit1 = log2( 3*fc / fmin );
crit2 = log2( fc/4 );
crit = floor( max(crit1, crit2) );

w = 2^(crit + 1);

end