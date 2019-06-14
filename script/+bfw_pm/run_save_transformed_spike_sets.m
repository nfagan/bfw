tmp_dataroot = '/Volumes/external/data/changlab/brains/free_viewing/';

spike_sets = bfw_pm.load_spike_sets( tmp_dataroot );

%%

[spike_dat, spike_labels, t] = ...
  bfw_pm.transform_cc_spike_sets( spike_sets.SETs, spike_sets.region_labels );

%%

bfw_pm.save_spike_data( tmp_dataroot, spike_dat, spike_labels, t );