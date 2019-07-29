function outs = bfw_load_stim_events(varargin)

defaults = bfw.get_common_make_defaults();
inputs = { 'stim', 'meta', 'stim_meta' };

[~, runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();

results = runner.run( @main );
outputs = shared_utils.pipeline.extract_outputs_from_results( results );

if ( isempty(outputs) )
  outs = struct();
  outs.stim_times = [];
  outs.labels = fcat();
else
  outs = shared_utils.struct.soa( outputs );
end

end

function outs = main(files)

stim_file = shared_utils.general.get( files, 'stim' );
meta_file = shared_utils.general.get( files, 'meta' );
stim_meta_file = shared_utils.general.get( files, 'stim_meta' );

labels = bfw.make_stim_labels( numel(stim_file.stimulation_times), numel(stim_file.sham_times) );
join( labels, bfw.struct2fcat(meta_file), bfw.stim_meta_to_fcat(stim_meta_file) );

outs = struct();
outs.labels = labels;
outs.stim_times = [ stim_file.stimulation_times(:); stim_file.sham_times(:) ];

end