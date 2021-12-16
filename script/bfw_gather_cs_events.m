function outs = bfw_gather_cs_events(varargin)

defaults = bfw.get_common_make_defaults();
defaults.include_labels = false;
params = bfw.parsestruct( defaults, varargin );

inputs = { 'cs_task_events/m1' };

if ( params.include_labels )
  inputs{end+1} = 'cs_labels/m1';
end

[~, runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();
runner.get_identifier_func = @get_cs_unified_filename;
runner.get_directory_name_func = @get_directory_name;

results = runner.run( @gather, params );
outputs = shared_utils.pipeline.extract_outputs_from_results( results );

outs = struct();

if ( isempty(outputs) )
  outs.events = [];
  outs.event_key = bfw.empty_event_key();
  outs.labels = fcat();
else
  [outs.events, outs.event_key] = merge_events( outputs );
  outs.labels = vertcat( fcat, outputs.labels );
end

end

function [events, keys] = merge_events(outputs)

keys = arrayfun( @(x) x.event_key, outputs, 'un', 0 );
keys = unique( vertcat(keys{:}) );

all_events = cell( numel(outputs), 1 );

for i = 1:numel(outputs)
  events = nan( rows(outputs(i).events), numel(keys) );
  
  [~, assign_ind] = ismember( outputs(i).event_key, keys );
  events(:, assign_ind) = outputs(i).events;
  
  all_events{i} = events;
end

events = vertcat( all_events{:} );

end

function name = get_directory_name(p)
% remove m1/
[~, name] = fileparts( fileparts(p) );
end

function un_filename = get_cs_unified_filename(file, ~)

un_filename = file.cs_unified_filename;

end

function out = gather(files, params)

import shared_utils.general.*;

events_file = get( files, 'cs_task_events' );

events = events_file.event_times;
event_key = events_file.event_key;
session = events_file.cs_unified_filename(1:8);

if ( params.include_labels )
  labels_file = get( files, 'cs_labels' );
  labels = addsetcat( labels_file.labels, 'session', session );
else
  labels = fcat.create( ...
    'session', session ...
  );
  repmat( labels, rows(events) );
end

out = struct();
out.events = events;
out.event_key = event_key;
out.labels = labels;

end