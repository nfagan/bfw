function labels = add_day_time_quantile_labels(labels, stim_ts, num_quantiles, start_time_file)

cat_name = 'day_time_quantile';
addcat( labels, cat_name );

start_time = start_time_file.first_run_start_time;
session_dur = start_time_file.last_run_stop_time - start_time;

quant_dur = session_dur / num_quantiles;
had_match = false( size(stim_ts) );

for i = 1:num_quantiles
  min_dur = start_time + (i-1) * quant_dur;
  max_dur = min_dur + quant_dur;
  
  within_quant = stim_ts >= min_dur & stim_ts < max_dur;
  had_match(within_quant) = true;
  
  for j = 1:numel(stim_ts)
    if ( within_quant(j) )
      setcat( labels, cat_name, sprintf('%s__%d', cat_name, i), j );
    end
  end
end

end