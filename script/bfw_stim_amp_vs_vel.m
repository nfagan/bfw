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

function outs = amp_vel_main(stim_file, meta_file, stim_meta_file, t_file, pos_file, fix_file, params)

stim_times = [ stim_file.stimulation_times(:); stim_file.sham_times(:) ];

t = t_file.t;
m1_fix = fix_file.m1;
m1_pos = pos_file.m1;

look_ahead = params.look_ahead;

[fix_starts, durs] = shared_utils.logical.find_starts( m1_fix, params.minimum_fix_length );

amps = rownan( numel(stim_times) );
vels = rownan( rows(amps) );

labs = make_stim_labs( stim_file, meta_file, stim_meta_file );

for i = 1:numel(stim_times)
  nearest_idx = shared_utils.sync.nearest( t, stim_times(i) );
  nearest_t = t(nearest_idx);
  
  fix_after = find( fix_starts > nearest_idx, 2 );
  fix_start_inds = fix_starts(fix_after);
  fix_stop_inds = fix_start_inds + durs(fix_after) - 1;
  
  t_after = t(fix_start_inds);
  
  offsets = t_after - nearest_t;
  
  is_ib = offsets <= look_ahead & offsets > 0;
  
  % need 2 fixation starts to calculate a saccade amplitude / vel between
  % them.
  if ( nnz(is_ib) ~= 2 ), continue; end
  
  % saccade is end of first fixation -> start of next fixation
  is_saccade_ind = fix_stop_inds(1)+1:fix_start_inds(2);
  
  if ( numel(is_saccade_ind) < params.minimum_saccade_length )
    continue;
  end
  
  start_ind = fix_stop_inds(1);
  stop_ind = fix_start_inds(2);
  
  m1_saccade_start = m1_pos(:, start_ind);
  m1_saccade_stop = m1_pos(:, stop_ind);
  m1_t = t(stop_ind) - t(start_ind);
  
  x0 = m1_saccade_start(1);
  y0 = m1_saccade_start(2);
  x1 = m1_saccade_stop(1);
  y1 = m1_saccade_stop(2);
  
  amps(i) = bfw.distance( x0, y0, x1, y1 );
  vels(i) = amps(i) / m1_t;
end

outs.amplitudes = amps;
outs.velocities = vels;
outs.labels = labs;

end