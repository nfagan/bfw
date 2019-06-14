function spike_sets = load_spike_sets(data_root)

data_p = fullfile( data_root, 'analyses/spike_rate' );
spike_sets = load( fullfile(data_p, 'brains_psth_sets_rate.mat') );
region_labels = load( fullfile(data_p, 'region_labels.mat') );

spike_sets.region_labels = region_labels.region_vector;

end