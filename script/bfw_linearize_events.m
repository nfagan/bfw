function out = bfw_linearize_events(varargin)

defaults = bfw.get_common_make_defaults();

inputs = { 'raw_events', 'meta', 'stim_meta' };

[params, runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();

results = runner.run( @linearize, params );
outputs = [ results([results.success]).output ];

out = sort_by_date( merge_outputs(outputs) );

end

function out = linearize(files, params)

events_file = shared_utils.general.get( files, 'raw_events' );
meta_file = shared_utils.general.get( files, 'meta' );
stim_meta_file = shared_utils.general.get( files, 'stim_meta' );

event_key = events_file.event_key;

start_times = events_file.events(:, event_key('start_time'));
[~, I] = sort( start_times );

sorted_events = events_file.events(I, :);
sorted_labels = fcat.from( events_file.labels(I, :), events_file.categories );

meta_labels = bfw.struct2fcat( meta_file );
stim_labels = bfw.stim_meta_to_fcat( stim_meta_file );
join( sorted_labels, meta_labels, stim_labels );
prune( bfw.add_monk_labels(sorted_labels) );

out = struct();
out.key_order = cellfun( @(x) event_key(x), get_expected_keys() );
out.event_key = event_key;
out.events = sorted_events;
out.labels = sorted_labels;

end

function out = merge_outputs(outputs)

out = struct();

if ( isempty(outputs) )
  out.events = [];
  out.labels = fcat();
  out.event_key = get_empty_map();
else
  key_order = vertcat( outputs.key_order );
  assert( size(unique(key_order, 'rows'), 1) == 1, 'Event columns are inconsistent.' );

  out.events = vertcat( outputs.events );
  out.labels = vertcat( fcat(), outputs.labels );
  out.event_key = outputs(1).event_key;
end

end

function outputs = sort_by_date(outputs)

[I, C] = findall( outputs.labels, 'date' );

[~, sorted_ind] = sort( datenum(C) );
I = vertcat( I{sorted_ind} );

assert( numel(unique(I)) == rows(outputs.labels) );

keep( outputs.labels, I );
outputs.events = outputs.events(I, :);

end

function map = get_empty_map()

keys = get_expected_keys();
map = containers.Map();

for i = 1:numel(keys)
  map(keys{i}) = [];  
end

end

function keys = get_expected_keys()

keys = { 'duration', 'length', 'start_index', 'stop_index', 'start_time', 'stop_time' };

end