function make_plex_start_stop_times(varargin)

defaults = bfw.get_common_make_defaults();

inputs = { 'sync', 'meta', 'plex_fp_time' };
outputs = 'plex_start_stop_times';

[params, runner] = bfw.get_params_and_loop_runner( inputs, outputs, defaults, varargin );
runner.convert_to_non_saving_with_output();

results = runner.run( @gather_starts );
outputs = shared_utils.struct.soa( shared_utils.pipeline.extract_outputs_from_results(results) );

session_I = findall( outputs.labels, 'session' );

if ( ~isempty(session_I) )
  shared_utils.io.require_dir( runner.output_directory );
end

for i = 1:numel(session_I)
  start_time = min( outputs.start_time(session_I{i}) );
  stop_time = max( outputs.stop_time(session_I{i}) );
  
  unified_filename = combs( outputs.labels, 'unified_filename', session_I{i} );
  
  for j = 1:numel(unified_filename)
    output_filename = fullfile( runner.output_directory, unified_filename{j} );
    
    start_stop_file = struct();
    start_stop_file.start_time = start_time;
    start_stop_file.stop_time = stop_time;
    
    start_stop_file.unified_filename = unified_filename;
    
    save( output_filename, 'start_stop_file' );
  end
end

end

function outs = gather_starts(files)

time_file = shared_utils.general.get( files, 'plex_raw_time' );
meta_file = shared_utils.general.get( files, 'meta' );

outs = struct();
outs.labels = bfw.struct2fcat( meta_file );
outs.start_time = min( time_file.m1 );
outs.stop_time = max( time_file.m1 );

end