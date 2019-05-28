function [f_osc, score] = osc_score(f, psd, freq_window)

f_ind = find( f >= freq_window(1) & f <= freq_window(2) );

assert( ~isempty(f_ind), 'No frequencies matched window.' );
assert( isequal(size(f), size(psd)), 'Frequencies do not match spectrum.' );

[~, window_peak_ind] = max( psd(f_ind) );
peak_ind = f_ind(window_peak_ind);

f_osc = f(peak_ind);
osc_psd = psd(peak_ind);

avg_psd = mean( psd );
score = osc_psd / avg_psd;

end