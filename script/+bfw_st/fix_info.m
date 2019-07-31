function outs = fix_info(varargin)

defaults = bfw.get_common_make_defaults();
defaults.config = bfw_st.default_config();
defaults.look_ahead = 5;
defaults.look_back = 0;

inputs = { 'raw_events', 'stim', 'meta', 'stim_meta' };

[params, runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();

results = runner.run( @main, params );

outputs = shared_utils.pipeline.extract_outputs_from_results( results );

if ( isempty(outputs) )
  outs.durations = [];
  outs.labels = fcat();
else
  outs = shared_utils.struct.soa( outputs );
end

end

function outs = main(files, params)

event_file = shared_utils.general.get( files, 'raw_events' );
stim_file = shared_utils.general.get( files, 'stim' );
meta_file = shared_utils.general.get( files, 'meta' );
stim_meta_file = shared_utils.general.get( files, 'stim_meta' );

stim_labels = bfw.make_stim_labels( numel(stim_file.stimulation_times), numel(stim_file.sham_times) );
meta_labels = bfw.struct2fcat( meta_file );
stim_meta_labels = bfw.stim_meta_to_fcat( stim_meta_file );
event_labels = fcat.from( event_file.labels, event_file.categories );

addcat( event_labels, 'stim_id' );
addcat( stim_labels, 'stim_id' );

stim_ids = arrayfun( @(x) sprintf('stim-%s', shared_utils.general.uuid()), 1:rows(stim_labels), 'un', 0 );

starts = bfw.event_column( event_file, 'start_time' );
stops = bfw.event_column( event_file, 'stop_time' );

durs = stops - starts;

look_ahead = params.look_ahead;
look_back = params.look_back;

stim_ts = [ stim_file.stimulation_times(:); stim_file.sham_times(:) ];

all_labels = fcat();
durations = [];

for i = 1:numel(stim_ts)
  within_range = starts >= stim_ts(i)+look_back & starts < stim_ts(i)+look_ahead;
  
  subset_durs = durs(within_range);
  subset_labs = event_labels(find(within_range));
  join( subset_labs, prune(stim_labels(i)), meta_labels, stim_meta_labels );
  
  if ( ~isempty(subset_labs) )
    setcat( subset_labs, 'stim_id', stim_ids{i} );
  end
  
  append( all_labels, subset_labs );
  
  durations = [ durations; durs(within_range) ];
end

assert_ispair( durations, all_labels );

outs = struct();
outs.durations = durations;
outs.labels = all_labels;

end