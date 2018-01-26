function raster = make_raster( spike_times, evt_times, min_t, max_t, fs )

n_samples = (max_t - min_t) .* fs;
id_times = (0:n_samples-1) .* 1/fs;
id_times = id_times + min_t;

raster = nan( numel(evt_times), numel(id_times) );

d = 10;


end