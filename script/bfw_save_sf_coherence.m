function results = bfw_save_sf_coherence(output_directory, varargin)

defaults = bfw.get_common_make_defaults();
defaults.rois = 'all';
defaults.keep_func = @bfw_keep_first_channel;

inputs = { 'raw_events', 'meta', 'lfp', 'spikes' };
output = output_directory;

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.save_func = @(file, var) save( file, 'var', '-v7.3' );

results = loop_runner.run( @sf_coh_main, params );
  
end

function coh_file = sf_coh_main(files, params)

coh_file = bfw.make.raw_sfcoherence( files ...
  , 'rois', params.rois ...
  , 'keep_func', params.keep_func ...
  , 'trial_average', true ...
  , 'trial_average_specificity', {'roi', 'looks_by'} ...
);

end