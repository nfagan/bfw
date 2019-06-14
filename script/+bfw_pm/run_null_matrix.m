spike_data = bfw_pm.load_spike_data( '/Volumes/external/data/changlab/brains/free_viewing' );

%%

spike_labels = fcat.from( spike_data.save_spike_labels );

%%

addcat( spike_labels, 'region' );

pm_outs = bfw_pm.null_matrix( spike_data.spike_dat, spike_labels, spike_data.t ...
  , 'iters', 1 ...
);

%%

