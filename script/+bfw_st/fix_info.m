function outs = fix_info(varargin)

defaults = bfw.get_common_make_defaults();
defaults.config = bfw_st.default_config();
defaults.look_ahead = 5;
defaults.look_back = 0;
defaults.num_day_time_quantiles = 2;
defaults.num_run_time_quantiles = 2;
defaults.stim_isi_quantile_edges = [6, 7];
defaults.iti_quantile_edges = [4, 6, 8];
defaults.event_mask_func = @(labels) find(labels, {'m1', 'exclusive_event'});
defaults.rois = {'eyes_nf', 'face'};
defaults.non_overlapping_pairs = {{'eyes_nf', 'face'}};
defaults.non_overlapping_each = { 'looks_by', 'event_type' };

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
  outs.current_itis = [];
  outs.next_duration_labels = fcat();
  
  outs.preceding_stim_durations = [];
  outs.preceding_stim_labels = fcat();
else
  outs = shared_utils.struct.soa( outputs );
end

add_preceding_stim_duration_quantile_labels( outs.preceding_stim_durations, outs.preceding_stim_labels );
apply_preceding_stim_duration_quantile_labels( outs.preceding_stim_labels, outs.labels );
apply_preceding_stim_duration_quantile_labels( outs.preceding_stim_labels, outs.current_duration_labels );
apply_preceding_stim_duration_quantile_labels( outs.preceding_stim_labels, outs.next_duration_labels );

end

function outs = main(files, params)

event_file = shared_utils.general.get( files, 'raw_events' );
stim_file = shared_utils.general.get( files, 'stim' );
meta_file = shared_utils.general.get( files, 'meta' );
stim_meta_file = shared_utils.general.get( files, 'stim_meta' );
start_time_file = shared_utils.general.get( files, 'plex_start_stop_times' );

% Extract the stim times and labels for each stim.
[stim_ts, stim_labels] = bfw_st.files_to_pair( stim_file, stim_meta_file, meta_file );
update_labels( stim_labels, stim_ts, start_time_file, params );

event_file = handle_rois_and_non_overlapping_events( event_file, params );

% Get start & stop times of looking events, and the duration of each event.
starts = bfw.event_column( event_file, 'start_time' );
stops = bfw.event_column( event_file, 'stop_time' );

durs = stops - starts;

% Make labels for the looking events -- including which roi and actor 
% (m1, m2, or mutual) are associated with each event.
event_labels = fcat.from( event_file.labels, event_file.categories );
% add_duration_quantile_labels( event_labels, durs );

addcat( event_labels, {'stim_id', 'stim_trigger'} );
addcat( stim_labels, {'stim_id', 'stim_trigger'} );

stim_ids = arrayfun( @(x) sprintf('stim-%s', shared_utils.general.uuid()), 1:rows(stim_labels), 'un', 0 );
% event_ids = arrayfun( @(x) sprintf('event-%s', shared_utils.general.uuid()), 1:rows(event_labels), 'un', 0 );
% setcat( event_labels, 'event_id', event_ids );

look_ahead = params.look_ahead;
look_back = params.look_back;

duration_labels = fcat();
durations = [];

current_durations = [];
current_offsets = [];
current_duration_labels = fcat();

current_duration_each = event_specificity();
current_duration_I = findall( event_labels, current_duration_each, params.event_mask_func(event_labels) );

next_durations = [];
next_offsets = [];
current_itis = [];
next_duration_labels = fcat();

[preceding_stim_durations, preceding_stim_labels] = ...
  get_preceding_stim_durations( starts, durs, event_labels, stim_ts, stim_labels, stim_ids );

for i = 1:numel(stim_ts)
  within_range = starts >= stim_ts(i)+look_back & starts < stim_ts(i)+look_ahead;
  
  for j = 1:numel(current_duration_I)
    curr_dur_ind = current_duration_I{j};
    
    nearest_start = find( starts(curr_dur_ind) < stim_ts(i), 1, 'last' );
    next_start = find( starts(curr_dur_ind) > stim_ts(i) , 1 , 'first' );
  
    if ( ~isempty(nearest_start) )
      nearest_ind = curr_dur_ind(nearest_start);
      
      curr_start = starts(curr_dur_ind(nearest_start));
      
      if ( isempty(next_start) )
        current_itis(end+1, 1) = nan;
      else
        current_itis(end+1, 1) = starts(curr_dur_ind(next_start)) - curr_start;
      end
      
      current_durations(end+1, 1) = durs(nearest_ind);
      current_offsets(end+1, 1) = stim_ts(i) - curr_start;
      
      subset_current_dur_labels = ...
        make_labels( event_labels, stim_labels, nearest_ind, i, stim_ids );      
      
      append( current_duration_labels, subset_current_dur_labels );      
    end
    
    if ( ~isempty(next_start) )
      next_ind = curr_dur_ind(next_start);
      
      if ( next_start <= 1 )
        prev_ind = 0;
      else
        prev_ind = curr_dur_ind(next_start-1);
      end
      
      next_durations(end+1, 1) = durs(next_ind);
      
      if ( prev_ind < 1 )
        next_offsets(end+1, 1) = nan;
      else
        next_offsets(end+1, 1) = starts(next_ind) - starts(prev_ind);
      end
      
      subset_next_dur_labels = ...
        make_labels( event_labels, stim_labels, next_ind, i, stim_ids );
    
      add_iti_quantile_labels( subset_next_dur_labels, next_offsets(end), params.iti_quantile_edges );
      
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
outs.current_offsets = current_offsets;
outs.current_duration_labels = current_duration_labels;

outs.current_itis = current_itis;
outs.next_durations = next_durations;
outs.next_offsets = next_offsets;
outs.next_duration_labels = next_duration_labels;

outs.preceding_stim_durations = preceding_stim_durations;
outs.preceding_stim_labels = preceding_stim_labels;

end

function events_file = handle_rois_and_non_overlapping_events(events_file, params)

rois = params.rois;
non_overlapping_pairs = params.non_overlapping_pairs;
each = params.non_overlapping_each;

events_file = bfw_st.make_non_overlapping_events_file( events_file, rois, non_overlapping_pairs, each );

end

function [durations, labels] = get_preceding_stim_durations(starts, durs, event_labels, stim_ts, stim_labels, stim_ids)

[durations, labels] = bfw_st.get_preceding_stim_durations( starts, durs, event_labels, stim_ts, stim_labels, stim_ids );

end

function spec = event_specificity()

spec = bfw_st.event_specificity();

end

function spec = day_event_specificity()

spec = bfw_st.day_event_specificity();

end

function apply_preceding_stim_duration_quantile_labels(src_labels, dest_labels)

quant_cat = 'preceding_stim_duration_quantile';
addcat( dest_labels, quant_cat );
[src_stim_id_I, src_stim_ids] = findall( src_labels, 'stim_id' );

for i = 1:numel(src_stim_id_I)
  dest_stim_ind = find( dest_labels, src_stim_ids{i} );
  src_label = cellstr( src_labels, quant_cat, src_stim_id_I{i} );
  setcat( dest_labels, quant_cat, src_label, dest_stim_ind );  
end

end

function add_preceding_stim_duration_quantile_labels(durations, labels)

each = union(day_event_specificity,'task_type');
[quants, each_I] = dsp3.quantiles_each( durations, labels, 2, each, {} );
dsp3.add_quantile_labels( labels, quants, 'preceding_stim_duration_quantile' );

end

% function labels = add_previous_duration_quantile_labels(labels, quants, each_I)
% 
% for i = 1:numel(each_I)  
%   src_ind = each_I{i}(1:end-1);
%   dest_ind = each_I{i}(2:end);
%   
%   quant_labels = cellstr( labels, 'duration_quantile', src_ind );
%   quant_labels = cellfun( @(x) sprintf('previous_%s', x), quant_labels, 'un', 0 );
%   
%   is_missing = isnan( quants(src_ind) );
%   quant_labels(is_missing) = [];
%   dest_ind(is_missing) = [];
%   
%   addcat( labels, 'previous_duration_quantile' );
%   setcat( labels, 'previous_duration_quantile', quant_labels, dest_ind );
% end
% 
% end

function add_iti_quantile_labels(labels, iti, iti_quantile_edges)

edges = [ -inf, iti_quantile_edges(:)', inf ];
quantile_ind = find( histc(iti, edges) );

if ( isempty(quantile_ind) )
  quantile_ind = nan;
end

quantile_cat = 'iti_quantile';
label = sprintf( '%s__%d', quantile_cat, quantile_ind );

addsetcat( labels, quantile_cat, label );

end

function update_labels(stim_labels, stim_ts, start_time_file, params)

bfw_st.add_stim_isi_quantile_labels( stim_labels, stim_ts, params.stim_isi_quantile_edges );

bfw_st.add_per_stim_labels( stim_labels, stim_ts );
bfw_st.add_day_time_quantile_labels( stim_labels, stim_ts, params.num_day_time_quantiles, start_time_file );
bfw_st.add_run_time_quantile_labels( stim_labels, stim_ts, params.num_run_time_quantiles, start_time_file );

prune( stim_labels );

end

function subset_labs = make_labels(event_labels, stim_labels, event_inds, stim_ind, stim_ids)

subset_labs = bfw_st.join_event_stim_labels( event_labels, stim_labels, event_inds, stim_ind, stim_ids );

end

function mask = m1_exclusive_only()



end