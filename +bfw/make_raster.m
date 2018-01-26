function raster = make_raster( spike_times, evt_times, min_t, max_t, fs )

n_samples = (max_t - min_t) .* fs;
id_times = (0:n_samples-1) .* 1/fs;
id_times = id_times + min_t;

raster = false( numel(evt_times), numel(id_times) );

for i = 1:numel(evt_times)
  min_evt = evt_times(i) + min_t;
  max_evt = evt_times(i) + max_t;
  
  ind = spike_times >= min_evt & spike_times <= max_evt;
  
  subset_spikes = spike_times(ind);
  
  for j = 1:numel(subset_spikes)
    [~, nearest] = min( abs(id_times-(subset_spikes(j)-evt_times(i))) );
    raster(i, nearest) = true;
  end
end

end