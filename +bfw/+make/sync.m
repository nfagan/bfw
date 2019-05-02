function sync_file = sync(files, conf)

%   SYNC -- Make plexon-matlab sync times file.
%
%     See also bfw.make.help
%
%     IN:
%       - `files` (containers.Map, struct)
%       - `conf` (struct) |OPTIONAL|
%     FILES:
%       - 'unified'
%     OUT:
%       - `sync_file` (struct)

bfw.validatefiles( files, 'unified' );

unified = shared_utils.general.get( files, 'unified' );
unified_filename = bfw.try_get_unified_filename( unified );

if ( nargin < 2 || isempty(conf) )
  conf = bfw.config.load();
else
  bfw.util.assertions.assert__is_config( conf );
end

pl2_map = bfw.get_plex_channel_map();
copy_fields = { 'unified_filename', 'plex_filename', 'plex_directory' };

data_root = bfw.dataroot( conf );
  
first = 'm1';

sync_id = bfw.field_or( unified.(first), 'plex_sync_id', 'm2' );
task_type = unified.(first).task_type;

pl2_file = unified.(first).plex_filename;
pl2_dir = fullfile( unified.(first).plex_directory{:} );
pl2_dir = fullfile( data_root, pl2_dir );

pl2_file = fullfile( pl2_dir, pl2_file );

if ( ~shared_utils.io.fexists(pl2_file) )
  error( 'Skipping "%s" because the .pl2 file "%s" does not exist.' ...
    , unified_filename, pl2_file );
end

sync_pulse_raw = PL2Ad( pl2_file, pl2_map('sync_pulse') );
start_pulse_raw = PL2Ad( pl2_file, pl2_map('session_start') );
reward_pulse_raw = PL2Ad( pl2_file, pl2_map('reward') );

sync_pulses = bfw.get_pulse_indices( sync_pulse_raw.Values );
reward_pulses = bfw.get_pulse_indices( reward_pulse_raw.Values );
start_pulses = bfw.get_pulse_indices( start_pulse_raw.Values );

binned_sync = bfw.bin_pulses( sync_pulses, start_pulses );
binned_reward = bfw.bin_pulses( reward_pulses, start_pulses );

sync_index = unified.(first).plex_sync_index;

if ( sync_index < 1 || sync_index > numel(binned_sync) )
  error( 'Sync index for "%s" must be > 1 and <= %d; was %d.' ...
    , unified_filename, numel(binned_sync), sync_index );
end

if ( sync_index < numel(binned_sync) )
  diff_next = start_pulses(sync_index+1) - max( binned_sync{sync_index} );
  fprintf( '\n %0.3f', diff_next );
end

id_times = (0:numel(sync_pulse_raw.Values)-1) .* (1/sync_pulse_raw.ADFreq);

current_plex_sync = binned_sync{sync_index};
current_plex_reward = binned_reward{sync_index};
current_plex_start = start_pulses(sync_index);

if ( numel(current_plex_sync) == 0 )
  error( 'No sync times were found for "%s" and index %d. Check your plex_sync_map.json file.' ...
    , unified_filename, sync_index );
end

mat_sync = unified.(sync_id).plex_sync_times;
mat_reward_sync = unified.(sync_id).reward_sync_times;

if ( ~bfw.is_image_task(task_type) )
  assert( numel(mat_reward_sync) == numel(current_plex_reward) ...
    , 'Mismatch between number of plex reward sync and mat reward sync pulses for "%s".' ...
    , unified_filename );
end

[mat_sync, current_plex_sync] = ...
  validate_sync_times( mat_sync, current_plex_sync, task_type, unified_filename );

current_plex_sync = [ current_plex_start; current_plex_sync ];
current_plex_sync = arrayfun( @(x) id_times(x), current_plex_sync );

current_plex_reward = arrayfun( @(x) id_times(x), current_plex_reward );

sync_file = struct();

sync_file.reward = [ mat_reward_sync(:), current_plex_reward(:) ];
sync_file.plex_sync = [ mat_sync(:), current_plex_sync(:) ];
sync_file.sync_key = { 'mat', 'plex' };

for j = 1:numel(copy_fields)
  sync_file.(copy_fields{j}) = unified.(first).(copy_fields{j});
end

end

function [mat_sync, plex_sync] = validate_sync_times(mat_sync, plex_sync, task_type, unified_filename)

n_mat = numel( mat_sync );
n_plex = numel( plex_sync );

if ( bfw.is_image_task(task_type) )
  med_diff = median( diff(plex_sync) );
  last_diff = plex_sync(end) - plex_sync(end-1);
  
  if ( last_diff > med_diff * 1.5 )
    plex_sync(end) = plex_sync(end-1) + med_diff;
  end
  
  if ( n_mat == n_plex + 2 )
    plex_sync(end+1) = plex_sync(end) + med_diff;
    n_plex = numel( plex_sync );
  end
end

if ( n_mat ~= n_plex + 1 )
  error( 'Mismatch between number of plex sync and mat sync pulses for "%s".' ...
    , unified_filename );
end

end