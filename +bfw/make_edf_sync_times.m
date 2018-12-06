function results = make_edf_sync_times(varargin)

defaults = bfw.get_common_make_defaults();

inputs = { 'unified', 'edf' };
output = 'edf_sync';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

results = loop_runner.run( @make_edf_sync_times_main, params );

end

function sync_times_file = make_edf_sync_times_main(files, unified_filename, params)

unified_file = shared_utils.general.get( files, 'unified' );
edf_file = shared_utils.general.get( files, 'edf' );
  
fs = intersect( fieldnames(edf_file), {'m1', 'm2'} );

sync_times_file = struct();

for j = 1:numel(fs)   
  edf = edf_file.(fs{j}).edf;
  sync_times = unified_file.(fs{j}).plex_sync_times;

  [fixed_times, start_time] = get_edf_sync_times( edf, sync_times );

  sync_times_file.(fs{j}).unified_filename = unified_filename;
  sync_times_file.(fs{j}).edf_sync_times = fixed_times;
  sync_times_file.(fs{j}).edf_start_time = start_time;
end

end

function [fixed_times, start_time] = get_edf_sync_times(edf, sync_times)

t = edf.Events.Messages.time;
info = edf.Events.Messages.info;

is_sync_msg = strcmp( info, 'SYNCH' );
is_resync_msg = strcmp( info, 'RESYNCH' );

assert( sum(is_sync_msg) == 1, 'No starting synch message was found.' );
assert( sum(is_resync_msg) == numel(sync_times)-1 ...
  , 'Number of resync times does not match given number of mat sync times.' );

fixed_times = t(is_resync_msg);
start_time = t(is_sync_msg);

end