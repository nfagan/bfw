function start_inds = find_nearest_stim_time(t, stim_times)

non_nan = find( ~isnan(t) );
start_inds = non_nan( bfw.find_nearest(t(non_nan), stim_times) );

end