function labels = add_median_split_duration_labels(labels, durations, each, varargin)

assert_ispair( durations, labels );

I = findall( labels, each, varargin{:} );

quantile_cat = 'duration_quantile';
quant1_label = sprintf( '%s__1', quantile_cat );
quant2_label = sprintf( '%s__2', quantile_cat );
addcat( labels, quantile_cat );

for i = 1:numel(I)
  subset_durations = durations(I{i});
  med = nanmedian( subset_durations );
  
  quant1 = subset_durations <= med;
  quant2 = subset_durations > med;
  
  setcat( labels, quantile_cat, quant1_label, I{i}(quant1) );
  setcat( labels, quantile_cat, quant2_label, I{i}(quant2) );
end

prune( labels );

end