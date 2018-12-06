function results = make_sync_times(varargin)

defaults = bfw.get_common_make_defaults();

inputs = 'unified';
output = 'sync';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );

loop_runner.func_name = mfilename;

results = loop_runner.run( @make_sync_main, params );

end

function sync_file = make_sync_main(files, unified_filename, params)

unified = shared_utils.general.get( files, 'unified' );

pl2_map = bfw.get_plex_channel_map();
copy_fields = { 'unified_filename', 'plex_filename', 'plex_directory' };

data_root = bfw.dataroot( params.config );
  
sync_id = bfw.field_or( unified.m1, 'plex_sync_id', 'm2' );
first = 'm1';

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

assert( numel(mat_reward_sync) == numel(current_plex_reward) ...
  , 'Mismatch between number of plex reward sync and mat reward sync pulses for "%s".' ...
  , unified_filename );

%   current_sync should have one fewer element than mat_sync. This is
%   because the first mat_sync time corresponds to the start_sync pulse

assert( numel(mat_sync) == numel(current_plex_sync) + 1 ...
  , 'Mismatch between number of plex sync and mat sync pulses for "%s".' ...
  , unified_filename );

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