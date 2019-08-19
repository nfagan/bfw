function outs = fix_info(varargin)

defaults = bfw.get_common_make_defaults();
defaults.config = bfw_st.default_config();
defaults.look_ahead = 5;
defaults.look_back = 0;
defaults.num_day_time_quantiles = 2;
defaults.num_run_time_quantiles = 2;

inputs = { 'raw_events', 'stim', 'meta', 'stim_meta', 'plex_start_stop_times' };

[params, runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();

results = runner.run( @main, params );

outputs = shared_utils.pipeline.extract_outputs_from_results( results );

if ( isempty(outputs) )
  outs.durations = [];
  outs.labels = fcat();
  
  outs.current_durations = [];
  outs.current_duration_labels = fcat();
  
  outs.next_durations = [];
  outs.next_duration_labels = fcat();
  
else
  outs = shared_utils.struct.soa( outputs );
end

end

function outs = main(files, params)

event_file = shared_utils.general.get( files, 'raw_events' );
stim_file = shared_utils.general.get( files, 'stim' );
meta_file = shared_utils.general.get( files, 'meta' );
stim_meta_file = shared_utils.general.get( files, 'stim_meta' );
start_time_file = shared_utils.general.get( files, 'plex_start_stop_times' );

num_day_time_quantiles = params.num_day_time_quantiles;

[stim_ts, stim_labels] = bfw_st.files_to_pair( stim_file, stim_meta_file, meta_file );
bfw_st.add_per_stim_labels( stim_labels, stim_ts );
bfw_st.add_day_time_quantile_labels( stim_labels, stim_ts, num_day_time_quantiles, start_time_file );
bfw_st.add_run_time_quantile_labels( sitm_labels, stim_ts, num_day_time_quantiles, start_time_file );

event_labels = fcat.from( event_file.labels, event_file.categories );

addcat( event_labels, 'stim_id' );
addcat( stim_labels, 'stim_id' );

stim_ids = arrayfun( @(x) sprintf('stim-%s', shared_utils.general.uuid()), 1:rows(stim_labels), 'un', 0 );

starts = bfw.event_column( event_file, 'start_time' );
stops = bfw.event_column( event_file, 'stop_time' );

durs = stops - starts;

look_ahead = params.look_ahead;
look_back = params.look_back;

duration_labels = fcat();
durations = [];

current_durations = [];
current_duration_labels = fcat();

current_duration_each = { 'event_type', 'looks_by', 'roi' };
current_duration_I = findall( event_labels, current_duration_each );

next_durations = [];
next_duration_labels = fcat();

for i = 1:numel(stim_ts)
  within_range = starts >= stim_ts(i)+look_back & starts < stim_ts(i)+look_ahead;
  
  for j = 1:numel(current_duration_I)
    curr_dur_ind = current_duration_I{j};
    
    nearest_start = find( starts(curr_dur_ind) < stim_ts(i), 1, 'last' );
    next_start = find( starts(curr_dur_ind) > stim_ts(i) , 1 , 'first' );
  
    if ( ~isempty(nearest_start) )
      nearest_ind = curr_dur_ind(nearest_start);
      
      current_durations(end+1, 1) = durs(nearest_ind);
      subset_current_dur_labels = ...
      make_labels( event_labels, stim_labels, nearest_ind, i, stim_ids );
      
      append( current_duration_labels, subset_current_dur_labels );      
    end
    
    if ( ~isempty(next_start) )
      next_ind = curr_dur_ind(next_start);
      
      next_durations(end+1, 1) = durs(next_ind);
      subset_next_dur_labels = ...
      make_labels( event_labels, stim_labels, next_ind, i, stim_ids );
      
      append( next_duration_labels, subset_next_dur_labels );      
    end
  end
  
  subset_labs = make_labels( event_labels, stim_labels, find(within_range), i, stim_ids );
  
  append( duration_labels, subset_labs );
  
  durations = [ durations; durs(within_range) ];
end

assert_ispair( durations, duration_labels );

outs = struct();
outs.durations = durations;
outs.labels = duration_labels;

outs.current_durations = current_durations;
outs.current_duration_labels = current_duration_labels;

outs.next_durations = next_durations;
outs.next_duration_labels = next_duration_labels;

end

function subset_labs = make_labels(event_labels, stim_labels, event_inds, stim_ind, stim_ids)

subset_labs = event_labels(event_inds);
join( subset_labs, prune(stim_labels(stim_ind)) );

if ( ~isempty(subset_labs) )
  setcat( subset_labs, 'stim_id', stim_ids{stim_ind} );
end

end