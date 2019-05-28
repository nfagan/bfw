function outs = gather_spikes_and_events(varargin)

defaults = bfw.get_common_make_defaults();
inputs = { 'raw_events', 'meta', 'spikes' };

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
loop_runner.convert_to_non_saving_with_output();
loop_runner.is_parallel = false;

visited_spike_files = containers.Map();

results = loop_runner.run( @main, visited_spike_files, params );
outputs = [ results([results.success]).output ];

outs = struct();

if ( isempty(outputs) )
  outs.event_files = struct( [] );
  outs.meta_labs = fcat();
  outs.spike_filenames = {};
  outs.spike_files = containers.Map();
else
  outs.event_files = [ outputs.event_file ]';
  outs.meta_labs = vertcat( fcat, outputs.meta_labels );
  outs.spike_filenames = { outputs.spike_filename }';
  outs.spike_files = visited_spike_files;
end

end

function outs = main(files, visited_spike_files, params)

bfw.validatefiles( files, {'spikes', 'meta', 'raw_events'} );

[spike_file, spike_filename] = ...
  require_spike_file( files, bfw.gid('spikes', params.config), visited_spike_files );
meta_labels = bfw.struct2fcat( files('meta') );

outs = struct();
outs.meta_labels = meta_labels;
outs.event_file = files('raw_events');
outs.spike_filename = spike_filename;

end

function [spike_file, spike_filename] = require_spike_file(files, spike_p, visited_spike_files)

spike_file = shared_utils.general.get( files, 'spikes' );

if ( ~spike_file.is_link )
  spike_filename = spike_file.unified_filename;
  visited_spike_files(spike_filename) = spike_file;
  
else
  spike_filename = spike_file.data_file;
  
  if ( ~isKey(visited_spike_files, spike_filename) )
    spike_file = shared_utils.io.fload( fullfile(spike_p, spike_filename) );
    shared_utils.general.set( files, 'spikes', spike_file );
    visited_spike_files(spike_file.data_file) = spike_file;
  end
end

end