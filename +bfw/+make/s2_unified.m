function s2_unified(session_dir_path, plex_event_times)

paths = get_paths( session_dir_path );

m1_calibration = load_calibration_info( paths.m1_calibration );
m2_calibration = load_calibration_info( paths.m2_calibration );

[plex_file, plex_file_kind] = find_plex_session_file( session_dir_path );

if ( nargin < 2 )
  plex_event_times = load_plex_event_times( plex_file, plex_file_kind );
end

[plex_codes, plex_code_times] = plex_event_times_to_uint16( plex_event_times );

run_mats = shared_utils.io.findmat( paths.runs );
run_mats = run_mats(1);

for i = 1:numel(run_mats)
  run_file = load( run_mats{i} );
  [mat_sync_times, mat_start_uuids] = extract_mat_sync_info( run_file );
  plex_sync_times = make_plex_sync_times( mat_start_uuids, mat_sync_times, plex_codes, plex_code_times );
  
  unified_file = transform( run_file );
end

end

function sync_times = manual_plex_sync_times(num_start_uuids, plex_codes, plex_code_times)

%%

seq = plex_codes ~= intmax( 'uint16' );
[islands, durs] = shared_utils.logical.find_islands( seq );

assert( max(abs(durs - num_start_uuids)) == 1, 'Expected at most 1 sample of error.' );

sync_ts = {};
last_ind = 1;

for i = 1:numel(islands)-1
  d0 = durs(i);
  d1 = durs(i+1); 
  
  start_offset = d0 - num_start_uuids;
  stop_offset = d1 - num_start_uuids;
  
  start_ind = islands(i) + start_offset + num_start_uuids;
  stop_ind = islands(i+1) - stop_offset;
  
  sync_ts{i} = plex_code_times(start_ind:stop_ind);
  last_ind = stop_ind + 1;
end

sync_ts{end+1} = plex_code_times(last_ind:end);

end

function sync_times = make_plex_sync_times(start_uuids, mat_sync_times, plex_codes, plex_code_times)

%%

all_sync_times = manual_plex_sync_times( size(start_uuids, 1), plex_codes, plex_code_times );

end

function unified_file = transform(run_file)

program = run_file.program.Value;

unified_file = struct();
unified_file.plex_sync_times = program.plexon_sync_data.sync_times(:);
unified_file.plex_sync_start_uuids = program.plexon_sync_data.start_uuids;

end

function [sync_ts, start_uuids] = extract_mat_sync_info(run_file)

program = run_file.program.Value;

sync_ts = program.plexon_sync_data.sync_times(:);
start_uuids = program.plexon_sync_data.start_uuids;
start_uuids = mat_sync_start_uuids_to_uint16( start_uuids );

end

function calib_info = load_calibration_info(calib_dir)

calibration_mats = shared_utils.io.findmat( calib_dir );
if ( numel(calibration_mats) ~= 1 )
  error_expected_n_files( calib_dir, 'calibration', 1, numel(calibration_mats) );
end

src_calibration_info = load( calibration_mats{1} );

% Convert to format used in bfw.make_unified()
calib_info = struct();
calib_info.far_plane_key_map = src_calibration_info.key_map;
calib_info.far_plane_calibration = src_calibration_info.keys;

end

function recoded = mat_sync_start_uuids_to_uint16(uuids)

assert( size(uuids, 2) == 16, 'Expected uuids to be an Mx16 matrix.' );
recoded = zeros( size(uuids, 1), 1, 'uint16' );

for i = 1:size(uuids, 1)
  state = uint16( 0 );
  
  for j = 1:size(uuids, 2)
    if ( uuids(i, j) )
      state = bitset( state, j );
    end
  end
  
  recoded(i) = state;
end

end

function [recoded, recoded_ts] = plex_event_times_to_uint16(event_ts)

%%

assert( numel(event_ts) == 16, 'Expected 16 event channels; got %d.', numel(event_ts) );

event_ts = cellfun( @(x) unique(x(:)), event_ts, 'un', 0 );
ts = unique( vertcat(event_ts{:}) );

eps_thresh = 5;
diffs = diff( ts );
assert( min(diffs) < eps_thresh );

next_minima = -inf;

recoded = [];
recoded_ts = [];

for i = 1:numel(ts)
  ct = ts(i);
  
  if ( ct < next_minima )
    continue;
  end
  
  state = uint16( 0 );
  
  for j = 1:numel(event_ts)
    evts = event_ts{j};
    ind = bfw.find_nearest( evts, ct );
    match_t = evts(ind);
    
    if ( match_t == ct )
      tf = true;
    elseif ( abs(match_t - ct) <= eps_thresh )
      tf = true;
    else
      assert( ~any(event_ts{j} == ts(i)) );
      tf = false;
    end
    
    if ( tf )
      state = bitset( state, j );
    end
  end
  
  recoded(end+1, 1) = state;
  recoded_ts(end+1, 1) = ct;
  
  next_minima = ct + eps_thresh*2;
end

end

function event_ts = load_plex_event_times(plex_file, plex_file_kind)

num_channels = 16;
event_ts = cell( num_channels, 1 );

parfor i = 1:num_channels
  [n, ts] = plx_event_ts( plex_file, i );
  event_ts{i} = ts;
end

end

function [plx_file, kind] = find_plex_session_file(session_dir_path)

plx_file = shared_utils.io.find( session_dir_path, '.plx' );
if ( numel(plx_file) ~= 1 )
  error_expected_n_files( session_dir_path, 'plexon', 1, numel(plx_file) );
end

plx_file = plx_file{1};
kind = 'plx';

end

function paths = get_paths(session_dir_path)

paths = struct();
paths.runs = fullfile( session_dir_path, 'runs' );
paths.m1_calibration = fullfile( session_dir_path, 'face_calibration_m1' );
paths.m2_calibration = fullfile( session_dir_path, 'face_calibration_m2' );

fs = fieldnames( paths );
for i = 1:numel(fs)
  shared_utils.assertions.assert__is_dir( paths.(fs{i}), fs{i} );
end

end

function error_expected_n_files(path, kind, expected_num, actual_num)

error( 'Expected %d %s file(s) in %s; got %d.' ...
  , expected_num, kind, path, actual_num );

end