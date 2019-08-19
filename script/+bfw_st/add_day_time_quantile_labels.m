function labels = add_day_time_quantile_labels(labels, stim_ts, num_quantiles, start_time_file)

cat_name = 'day_time_quantile';
get_start_time_func = @() start_time_file.first_run_start_time;
get_stop_time_func = @() start_time_file.last_run_stop_time;

labels = bfw_st.add_time_quantile_labels( labels, stim_ts, num_quantiles ...
  , cat_name, get_start_time_func, get_stop_time_func );

end