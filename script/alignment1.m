%%

conf = bfw.config.load();

depends = conf.DEPENDS.repositories;
repo_dir = conf.PATHS.repositories;

for i = 1:numel(depends)
  addpath( genpath(fullfile(repo_dir, depends{i})) );
end

outerdir = fullfile( conf.PATHS.data_root, 'raw', '01162018' );

plex_dir = fullfile( outerdir, 'plex', 'sorted' );

m1_dir = fullfile( outerdir, 'm1' );
m2_dir = fullfile( outerdir, 'm2' );

m1_caldir = fullfile( m1_dir, 'calibration' );
m2_caldir = fullfile( m2_dir, 'calibration' );

%%

pl2_file = char( shared_utils.io.find(plex_dir, '.pl2') );
pl2_map = bfw.get_plex_channel_map();

spike_chan = 'SPK09';
spikes = PL2Ts( pl2_file, spike_chan, 0 );

sync_pulse_raw = PL2Ad( pl2_file, pl2_map('sync_pulse') );
start_pulse_raw = PL2Ad( pl2_file, pl2_map('session_start') );

ai_fs = start_pulse_raw.ADFreq;

sync_pulses = bfw.get_pulse_indices( sync_pulse_raw.Values );
start_pulses = bfw.get_pulse_indices( start_pulse_raw.Values );

id_times = bfw.get_ad_id_times( numel(sync_pulse_raw.Values), ai_fs );

binned = bfw.bin_pulses( sync_pulses, start_pulses );

% all_sync_pulses = binned([1, 3]);

all_sync_pulses = binned(1);

%%

load_func = @(x) bfw.unify_raw_data( shared_utils.io.fload(x) );

m1_data = cellfun( load_func, shared_utils.io.find(m1_dir, '.mat') );
m2_data = cellfun( load_func, shared_utils.io.find(m2_dir, '.mat') );

m1_calibrations = shared_utils.io.find( m1_caldir, '.mat' );
m2_calibrations = shared_utils.io.find( m2_caldir, '.mat' );

if ( ~isfield(m1_data, 'far_plane_calibration') )
  m1_roi = shared_utils.io.fload( m1_calibrations{end} );
  for i = 1:numel(m1_data), m1_data(i).far_plane_calibration = m1_roi; end
end

if ( ~isfield(m2_data, 'far_plane_calibration'))
  m2_roi = shared_utils.io.fload( m2_calibrations{end} );
  for i = 1:numel(m2_data), m2_data(i).far_plane_calibration = m2_roi; end
end

%%

IDX = 1;

m1 = m1_data(IDX);
m2 = m2_data(IDX);

pos_m1 = m1.position;
pos_m2 = m2.position;

t_m1 = m1.time;
t_m2 = m2.time;

%   transform m1 time points -> m2's clock. it should be m1 -> m2 because 
%   m2 sends pulses to plexon.

sync_m1 = m2.sync_times(:, 2);
sync_m2 = m2.sync_times(:, 1);

fs = 1/ai_fs;

N = 400;

[pos_aligned, t] = bfw.align_m1_m2( pos_m1, pos_m2, t_m1, t_m2, sync_m1, sync_m2, fs, N );

%%

m1_roi = m1.far_plane_calibration;
m2_roi = m2.far_plane_calibration;

map = brains.arduino.calino.get_calibration_key_roi_map();
consts = brains.arduino.calino.define_calibration_target_constants();
consts.FACE_WIDTH_CM = 8;
consts.FACE_HEIGHT_CM = 8;
consts.INTER_EYE_DISTANCE_CM = 8.25 - 4.75;
pad = brains.arduino.calino.define_padding();
pad.face.x = 2;
pad.face.y = 2;
pad.eyes.x = 2;
pad.eyes.y = 2;

face_m1 = brains.arduino.calino.bound_funcs.face_top_only( m1_roi, map, pad, consts );
eyes_m1 = brains.arduino.calino.bound_funcs.both_eyes( m1_roi, map, pad, consts );
face_m2 = brains.arduino.calino.bound_funcs.face_top_only( m2_roi, map, pad, consts );
eyes_m2 = brains.arduino.calino.bound_funcs.face_top_only( m2_roi, map, pad, consts );

eye_rect = eyes_m1;
face_rect = face_m1;


%%

m1_ib = bfw.bounds.rect( pos_aligned(1, :), pos_aligned(2, :), face_m1 );
m2_ib = bfw.bounds.rect( pos_aligned(3, :), pos_aligned(4, :), face_m2 );

% mutual = m1_ib & m2_ib;
mutual = m1_ib;

starts = shared_utils.logical.find_starts( mutual, 10 );

mat_evts = t( starts );

plex_sync_times = id_times( all_sync_pulses{IDX} );
%   the first sync time is the trial start pulse
plex_sync_m2 = m2.plex_sync_times(2:end);

assert( numel(plex_sync_m2) == numel(plex_sync_times) );

plex_evts = bfw.clock_a_to_b( mat_evts, plex_sync_m2, plex_sync_times );

[psth, binT] = looplessPSTH(spikes, plex_evts, -1, 1, 0.1);

figure(1); clf();

plot( binT, psth );

xlabel( 'Time (s) from mutual looks to face' );
ylabel( 'sp/s' );