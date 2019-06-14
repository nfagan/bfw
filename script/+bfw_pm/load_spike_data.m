function spike_data = load_spike_data(data_root)

data_filename = fullfile( data_root, 'analyses/spike_rate', 'spike_data.mat' );
spike_data = load( data_filename );

end