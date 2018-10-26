function outs = bfw_stim_amp_vs_vel(varargin)

import shared_utils.io.fload;

defaults = bfw.get_common_make_defaults();
defaults.fixations_subdir = 'arduino_fixations';
defaults.samples_subdir = 'aligned_binned_raw_samples';
defaults.look_ahead = 5;
defaults.minimum_fix_length = 1;

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
fsd = params.fixations_subdir;
samples_subdir = params.samples_subdir;

stim_p = bfw.gid( 'stim', conf );
samp_p = bfw.gid( samples_subdir, conf );
fix_p = fullfile( samp_p, fsd );
time_p = fullfile( samp_p, 'time' );
pos_p = fullfile( samp_p, 'position' );

mats = bfw.rim( params.files, stim_p, params.files_containing );

for i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats), mfilename );
  
  stim_file = shared_utils.io.fload( mats{i} );
  
  unified_filename = stim_file.unified_filename;
  
  try
    pos_file = bfw.load_intermediate( pos_p, unified_filename );
    fix_file = bfw.load_intermediate( fix_p, unified_filename );
    t_file = bfw.load_intermediate( time_p, unified_filename );
    
    amp_vel_main( stim_file, t_file, pos_file, fix_file, params );
  catch err
    bfw.print_fail_warn( unified_filename, err.message );
    continue;
  end
end

end

function amp_vel_main(stim_file, t_file, pos_file, fix_file, params)

stim_times = [ stim_file.stimulation_times(:); stim_file.sham_times(:) ];

t = t_file.t;
m1_fix = fix_file.m1;
m1_pos = pos_file.m1;

look_ahead = params.look_ahead;

[fix_starts, durs] = shared_utils.logical.find_starts( m1_fix, params.minimum_fix_length );

amps = rownan( numel(stim_times) );
vels = rownan( rows(amps) );

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
  is_saccade_ind = fix_stop_inds(1)+1:fix_start_inds(2)-1;
  
  assert( ~isempty(is_saccade_ind) );
  
  m1_pos_saccade = m1_pos(:, is_saccade_ind);
  m1_saccade_time = diff(t(is_saccade_ind));
  
  d = 10;
end

end