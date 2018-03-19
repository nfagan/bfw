function filtered = zpfilter(signals, f1, f2, fs, n)

%   ZPFILTER -- Zero-phase filter.
%
%     IN:
%       - `signals` (double) -- MxN matrix of M trials by N samples.
%       - `f1` (double) -- Filter lower cutoff.
%       - `f2` (double) -- Filter upper cutoff.
%       - `n` (doulbe) -- Filter order. Default is 2.
%     OUT:
%       - `filtered` (double)

if ( nargin < 5 )
  n = 2;
end

f1 = f1 / (fs/2);
f2 = f2 / (fs/2);

[b, a] = butter( n, [f1, f2] );

filtered = filtfilt( b, a, signals' )';

end