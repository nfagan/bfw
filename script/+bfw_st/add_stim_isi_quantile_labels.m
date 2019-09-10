function stim_labels = add_stim_isi_quantile_labels(stim_labels, stim_ts, quantile_edges)

quantile_edges = [-inf, quantile_edges(:)', inf ];
quantile_cat = 'stim_isi_quantile';
addcat( stim_labels, quantile_cat );

[stim_ts, sorted_I] = sort( stim_ts );
isis = [ nan; diff(stim_ts) ];
    
for i = 1:numel(stim_ts)
    for j = 1:numel(quantile_edges)-1
        quantile_label = sprintf( '%s__%d', quantile_cat, j );

        min_edge = quantile_edges(j);
        max_edge = quantile_edges(j+1);

        if ( isis(i) >= min_edge && isis(i) < max_edge )
            setcat( stim_labels, quantile_cat, quantile_label, sorted_I(i) );
            break;
        end
    end
end

end