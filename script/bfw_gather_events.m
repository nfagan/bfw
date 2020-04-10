function outs = bfw_gather_events(varargin)

defaults = bfw.get_common_make_defaults();
defaults.event_subdir = '';

params = bfw.parsestruct( defaults, varargin );

inputs = { fullfile('raw_events', params.event_subdir), 'meta', 'stim_meta' };

[~, runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();

results = runner.run( @gather, params );
outputs = shared_utils.pipeline.extract_outputs_from_results( results );

outs = struct();

if ( isempty(outputs) )
  outs.events = [];
  outs.event_key = bfw.empty_event_key();
  outs.labels = fcat();
else
  outs.events = vertcat( outputs.events );
  outs.event_key = outputs(1).event_key;
  outs.labels = vertcat( fcat, outputs.labels );
end

end

function out = gather(files, params)

import shared_utils.general.*;

if ( isempty(params.event_subdir) )
  event_subdir = 'raw_events';
else
  event_subdir = params.event_subdir;
end

events_file = get( files, event_subdir );
meta_file = get( files, 'meta' );
stim_meta_file = get( files, 'stim_meta' );

events = events_file.events;
event_key = events_file.event_key;

labels = join( fcat.from(events_file) ...
  , bfw.struct2fcat(meta_file) ...
  , bfw.stim_meta_to_fcat(stim_meta_file) ...
);

out = struct();
out.events = events;
out.event_key = event_key;
out.labels = labels;

end