function sync_times_file = edf_sync_times(files)

%   EDF_SYNC_TIMES -- Create edf_sync_times file.
%
%     See also bfw.make.help
%
%     IN:
%       - `files` (containers.Map, struct)
%     FILES:
%       - 'unified'
%       - 'edf'
%     OUT:
%       - `sync_times_file` (struct)

bfw.validatefiles( files, {'unified', 'edf'} );

unified_file = shared_utils.general.get( files, 'unified' );
edf_file = shared_utils.general.get( files, 'edf' );

unified_filename = bfw.try_get_unified_filename( unified_file );
is_image_task = false;

try
  % Otherwise, not image task.
  is_image_task = bfw.is_image_task( unified_file.m1.task_type );
end
  
fs = intersect( fieldnames(edf_file), {'m1', 'm2'} );

sync_times_file = struct();

for j = 1:numel(fs)   
  edf = edf_file.(fs{j}).edf;
  sync_times = unified_file.(fs{j}).plex_sync_times;

  [fixed_times, start_time] = get_edf_sync_times( edf, sync_times, is_image_task );

  sync_times_file.(fs{j}).unified_filename = unified_filename;
  sync_times_file.(fs{j}).edf_sync_times = fixed_times;
  sync_times_file.(fs{j}).edf_start_time = start_time;
end

end

function [fixed_times, start_time] = get_edf_sync_times(edf, sync_times, is_image_task)

t = edf.Events.Messages.time;
info = edf.Events.Messages.info;

is_sync_msg = strcmp( info, 'SYNCH' );
is_resync_msg = strcmp( info, 'RESYNCH' );

assert( sum(is_sync_msg) == 1, 'No starting synch message was found.' );
assert( sum(is_resync_msg) == numel(sync_times)-1 ...
  , 'Number of resync times does not match given number of mat sync times.' );

if ( is_image_task )
  % Remove first sync time from image task.
  first_resync = find( is_resync_msg, 1 );
  first_sync = find( is_sync_msg, 1 );
  
  assert( first_resync < first_sync ...
    , ' Expected first sync message to precede start sync message for image task.' );
  
  is_resync_msg(first_resync) = false;
end

fixed_times = t(is_resync_msg);
start_time = t(is_sync_msg);

end