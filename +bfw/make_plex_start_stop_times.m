function make_plex_start_stop_times(varargin)

import shared_utils.struct.soa;
import shared_utils.pipeline.extract_outputs_from_results;

defaults = bfw.get_common_make_defaults();
defaults.session_duration = 5 * 60;

inputs = { 'sync', 'plex_fp_time', 'meta' };
outputs = 'plex_start_stop_times';

[params, runner] = bfw.get_params_and_loop_runner( inputs, outputs, defaults, varargin );
runner.convert_to_non_saving_with_output();

results = runner.run( @gather_starts, params.session_duration );
outputs = soa( extract_outputs_from_results(results) );

session_I = findall( outputs.labels, 'session' );

if ( ~isempty(session_I) )
  shared_utils.io.require_dir( runner.output_directory );
end

for i = 1:numel(session_I)
  session_ind = session_I{i};
  
  session_start_time = min( outputs.session_start_time(session_ind) );
  session_stop_time = max( outputs.session_stop_time(session_ind) );
  
  first_run_start_time = min( outputs.run_start_time(session_ind) );
  last_run_stop_time = max( outputs.run_stop_time(session_ind) );
  
  for j = 1:numel(session_ind)
    run_ind = session_ind(j);
    unified_filename = char( cellstr(outputs.labels, 'unified_filename', run_ind) );
    
    output_filename = fullfile( runner.output_directory, unified_filename );
    
    start_stop_file = struct();
    start_stop_file.unified_filename = unified_filename;
    start_stop_file.session_start_time = session_start_time;
    start_stop_file.session_stop_time = session_stop_time;
    start_stop_file.run_start_time = outputs.run_start_time(run_ind);
    start_stop_file.run_stop_time = outputs.run_stop_time(run_ind);
    start_stop_file.first_run_start_time = first_run_start_time;
    start_stop_file.last_run_stop_time = last_run_stop_time;
    
    save( output_filename, 'start_stop_file' );
  end
end

end

function outs = gather_starts(files, session_duration)

sync_file = shared_utils.general.get( files, 'sync' );
time_file = shared_utils.general.get( files, 'plex_fp_time' );
meta_file = shared_utils.general.get( files, 'meta' );

run_start = sync_file.plex_sync(1, 2);
run_stop = run_start + session_duration;

outs = struct();
outs.labels = bfw.struct2fcat( meta_file );
outs.run_start_time = run_start;
outs.run_stop_time = run_stop;
outs.session_start_time = min( time_file.id_times );
outs.session_stop_time = max( time_file.id_times );

end