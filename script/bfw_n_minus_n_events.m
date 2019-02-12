function out = bfw_n_minus_n_events(varargin)

defaults = bfw.get_common_make_defaults();
defaults.allowed_rois = { 'eyes_nf', 'mouth' };
defaults.allowed_looks_by = { 'm1' };
defaults.n_previous = 1;
defaults.minimum_inter_event_interval = -Inf;
defaults.maximum_inter_event_interval = Inf;

inputs = { 'raw_events', 'meta', 'stim_meta' };

[params, runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();

results = runner.run( @n_minus_n_events, params );
outputs = [ results([results.success]).output ];

out = struct();
out.params = params;
out.labels = vertcat( fcat, outputs.labels );
out.intervals = vertcat( outputs.intervals );

end

function out = n_minus_n_events(files, params)

meta_file =       shared_utils.general.get( files, 'meta' );
stim_meta_file =  shared_utils.general.get( files, 'stim_meta' );
events_file =     shared_utils.general.get( files, 'raw_events' );

meta_labs = bfw.struct2fcat( meta_file );
stim_meta_labs = bfw.stim_meta_to_fcat( stim_meta_file );
event_labs = fcat.from( events_file.labels, events_file.categories );

join( event_labs, meta_labs, stim_meta_labs );

event_times = events_file.events(:, events_file.event_key('start_time'));
[event_times, sorted_index] = sort( event_times );

keep( event_labs, sorted_index );

mask = rowmask( event_labs );

if ( ~isempty(params.allowed_rois) )
  mask = find( event_labs, params.allowed_rois, mask );
end

if ( ~isempty(params.allowed_looks_by) )
  mask = find( event_labs, params.allowed_looks_by, mask );
end

min_iei = params.minimum_inter_event_interval;
max_iei = params.maximum_inter_event_interval;

mask = keep_events_within_interval( event_times, mask, min_iei, max_iei );

prev_cats = { 'roi', 'looks_by' };
prev_cat_names = cellfun( @(x) sprintf('previous_%s', x), prev_cats, 'un', 0 );
addcat( event_labs, prev_cat_names );

N = params.n_previous;
begin = 1 + N;
stop = numel( mask );

for i = begin:stop
  previous_row = mask(i - N);
  current_row = mask(i);
  
  for j = 1:numel(prev_cats)
    prev_lab = char( cellstr(event_labs, prev_cats{j}, previous_row) );
    prev_lab = sprintf( 'previous_%s', prev_lab );
    
    setcat( event_labs, prev_cat_names{j}, prev_lab, current_row );
  end
end

out = struct();
out.labels = event_labs;
out.intervals = [ 0; diff(event_times(:)) ];

end

function mask = keep_events_within_interval(event_times, mask, minimum_iei, maximum_iei)

subset_times = event_times(mask);
is_nan_times = isnan( subset_times );
subset_times(is_nan_times) = [];

% Only include events within min iei < x < max iei
intervals = diff( subset_times(:) );
use_times = [ true; intervals > minimum_iei & intervals < maximum_iei ];

% Of event times that are non-nan, use those within the maximum_iei
all_use = false( size(subset_times) );
all_use(~is_nan_times) = use_times;

mask = mask(all_use);

end