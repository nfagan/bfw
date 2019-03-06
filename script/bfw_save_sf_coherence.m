function results = bfw_save_sf_coherence(output_directory, varargin)

defaults = bfw.get_common_make_defaults();
defaults.rois = 'all';

inputs = { 'raw_events', 'lfp', 'spikes' };
output = output_directory;

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );

results = loop_runner.run( @sf_coh_main, params );
  
end

function coh_file = sf_coh_main(files, params)

coh_file = bfw.make.raw_sfcoherence( files ...
  , 'rois', params.rois ...
  , 'keep_func', @keep_func ...
  , 'trial_average', true ...
  , 'trial_average_specificity', 'looks_by' ...
);

end

function [lfp_inds, spike_inds] = keep_func(lfp_labels, spike_labels)

region_I = findall( lfp_labels, 'region' );

lfp_inds = [];

for i = 1:numel(region_I)
  channel_I = findall( lfp_labels, 'channel', region_I{i} );
  lfp_inds = union( lfp_inds, channel_I{1} );
end

spike_inds = findnone( spike_labels, 'unit_rating__0' );

end