function outs = bfw_stim_amp_vs_vel(varargin)

import shared_utils.io.fload;

defaults = bfw.get_common_make_defaults();
defaults.fixations_subdir = 'arduino_fixations';
defaults.samples_subdir = 'aligned_binned_raw_samples';
defaults.look_ahead = 5;
defaults.minimum_fix_length = 1;
defaults.minimum_saccade_length = 2;

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
fsd = params.fixations_subdir;
samples_subdir = params.samples_subdir;

stim_p = bfw.gid( 'stim', conf );
meta_p = bfw.gid( 'meta', conf );
samp_p = bfw.gid( samples_subdir, conf );
fix_p = fullfile( samp_p, fsd );
time_p = fullfile( samp_p, 'time' );
pos_p = fullfile( samp_p, 'position' );
stim_meta_p = bfw.gid( 'stim_meta', conf );

mats = bfw.rim( params.files, stim_p, params.files_containing );

s = [ numel(mats), 1 ];

velocities = cell( s );
amps = cell( s );
labels = cell( s );
ns = cell( s );
is_ok = true( s );

parfor i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats), mfilename );
  
  stim_file = shared_utils.io.fload( mats{i} );
  
  unified_filename = stim_file.unified_filename;
 
  if ( false ), is_ok(i); end
  
  try
    pos_file = bfw.load_intermediate( pos_p, unified_filename );
    fix_file = bfw.load_intermediate( fix_p, unified_filename );
    t_file = bfw.load_intermediate( time_p, unified_filename );
    meta_file = bfw.load_intermediate( meta_p, unified_filename );
    stim_meta_file = bfw.load_intermediate( stim_meta_p, unified_filename );
    
    outs = amp_vel_main( stim_file, meta_file, stim_meta_file ...
      , t_file, pos_file, fix_file, params );
    
    velocities{i} = outs.velocities;
    amps{i} = outs.amplitudes;
    ns{i} = outs.ns;
    labels{i} = outs.labels;    
  catch err
    bfw.print_fail_warn( unified_filename, err.message );
    
    is_ok(i) = false;
    continue;
  end
end

velocities = velocities(is_ok);
amps = amps(is_ok);
labels = labels(is_ok);

outs = struct();
outs.velocities = vertcat( velocities{:} );
outs.amps = vertcat( amps{:} );
outs.labels = vertcat( fcat(), labels{:} );
outs.ns = vertcat( ns{:} );

end

function outs = amp_vel_main(stim_file, meta_file, stim_meta_file, t_file, pos_file, fix_file, params)

stim_times = [ stim_file.stimulation_times(:); stim_file.sham_times(:) ];

t = t_file.t;
m1_fix = fix_file.m1;
m1_pos = pos_file.m1;

look_ahead = params.look_ahead;

[fix_starts, durs] = shared_utils.logical.find_starts( m1_fix, params.minimum_fix_length );

amps = rownan( numel(stim_times) );
vels = rownan( rows(amps) );
ns = rownan( rows(amps) );

labs = make_stim_labs( stim_file, meta_file, stim_meta_file );

for i = 1:numel(stim_times)
  nearest_idx = shared_utils.sync.nearest( t, stim_times(i) );
  nearest_t = t(nearest_idx);
  
  fix_after = find( fix_starts > nearest_idx, 2 );
  fix_start_inds = fix_starts(fix_after);
  fix_stop_inds = fix_start_inds + durs(fix_after) - 1;
  
  t_after = t(fix_start_inds);
  
  offsets = t_after - nearest_t;
  
  is_ib = offsets > 0 & offsets <= look_ahead;
  
  % need 2 fixation starts to calculate a saccade amplitude / vel between
  % them.
  if ( nnz(is_ib) ~= 2 ), continue; end
  
  % saccade is end of first fixation -> start of next fixation
  is_saccade_ind = fix_stop_inds(1)+1:fix_start_inds(2);
  
  if ( numel(is_saccade_ind) < params.minimum_saccade_length ), continue; end
  
  [a, v] = get_amp_vel_old_method( t, m1_pos, is_saccade_ind );
%   [a, v] = get_amp_vel_end_to_end( t, m1_pos, is_saccade_ind );
%   [a, v] = get_amp_vel_sample_by_sample( t, m1_pos, is_saccade_ind );
  
  amps(i) = a;
  vels(i) = v;
  ns(i) = numel( is_saccade_ind );
end

outs.amplitudes = amps;
outs.velocities = vels;
outs.ns = ns;
outs.labels = labs;

end

function l = make_stim_labs(stim_file, meta_file, stim_meta_file)

n_stim = numel( stim_file.stimulation_times );
n_sham = numel( stim_file.sham_times );

if ( n_stim + n_sham == 0 )
  l = fcat();
  return
end

l = join( bfw.make_stim_labels(n_stim, n_sham), bfw.struct2fcat(meta_file) );

if ( stim_meta_file.used_stimulation )
  protocol_name = stim_meta_file.protocol_name;
else
  protocol_name = 'no_stimulation';
end

addsetcat( l, 'stim_protocol', protocol_name );
addsetcat( l, 'looks_by', 'm1' );

end

function [a, v] = get_amp_vel_old_method(t, pos, is_saccade_ind)

filt_order = 4;
frame_len = min( 21, numel(is_saccade_ind) );

if ( mod(frame_len, 2) == 0 )
  frame_len = frame_len - 1;
end

filt_order = min( filt_order, frame_len - 1 );

x = sgolayfilt( pos(1, is_saccade_ind), filt_order, frame_len );
y = sgolayfilt( pos(2, is_saccade_ind), filt_order, frame_len );

xamp = abs( x(end) - x(1) );
yamp = abs( y(end) - y(1) );

subset_t = t(is_saccade_ind);
diff_t = diff( subset_t );

vx = diff( x ) ./ diff_t;
vy = diff( y ) ./ diff_t;

x_peakvel = max( abs(vx) );
y_peakvel = max( abs(vy) );

a = mean( [xamp, yamp] );
v = mean( [x_peakvel, y_peakvel] );

end

function [a, v] = get_amp_vel_end_to_end(t, pos, is_saccade_ind)

start_ind = is_saccade_ind(1);
stop_ind = is_saccade_ind(end);

saccade_start = pos(:, start_ind);
saccade_stop = pos(:, stop_ind);
dt = t(stop_ind) - t(start_ind);

x0 = saccade_start(1);
y0 = saccade_start(2);
x1 = saccade_stop(1);
y1 = saccade_stop(2);

a = bfw.distance( x0, y0, x1, y1 );
v = a / dt;

end

function [a, v] = get_amp_vel_sample_by_sample(t, pos, is_saccade_ind)

vs = zeros( numel(is_saccade_ind) - 1, 1 );

for i = 1:numel(is_saccade_ind)-1
  start_ind = is_saccade_ind(i);
  stop_ind = is_saccade_ind(i+1);
  
  start = pos(:, start_ind);
  stop = pos(:, stop_ind);
  
  dt = t(stop_ind) - t(start_ind);
  
  vs(i) = bfw.distance( start(1), start(2), stop(1), stop(2) ) / dt;
end

a = get_amp_vel_end_to_end( t, pos, is_saccade_ind );
v = max( vs );

end