function save_spike_data(data_root, spike_dat, spike_labels, t)

data_filename = fullfile( data_root, 'analyses/spike_rate', 'spike_data.mat' );

save_spike_labels = gather( spike_labels );

save( data_filename, 'spike_dat', 'save_spike_labels', 't', '-v7.3' );

end