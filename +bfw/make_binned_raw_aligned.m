function make_binned_raw_aligned(varargin)

import shared_utils.io.fload;

ff = @fullfile;

defaults = bfw.get_common_make_defaults();
defaults.window_size = 10;
defaults.step_size = 10;
defaults.discard_uneven = true;
defaults.kinds = get_default_kinds();

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;
osd = params.output_subdir;
kinds = shared_utils.cell.ensure_cell( params.kinds );

aligned_samples_p = bfw.gid( ff('aligned_raw_samples', isd), conf );
time_p = fullfile( aligned_samples_p, 'time' );

aligned_binned_p = bfw.gid( ff('aligned_binned_raw_samples', osd), conf );

mats = bfw.require_intermediate_mats( params.files, time_p, params.files_containing );

params.is_binned = true;

parfor i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats), mfilename );
  
  time_file = fload( mats{i} );
  
  unified_filename = time_file.unified_filename;
  
  if ( ismember('time', kinds) )
    make_time( aligned_binned_p, time_file, params );
  end
  
  if ( ismember('position', kinds) )
    make_position( aligned_samples_p, aligned_binned_p, unified_filename, params );
  end
  
  if ( ismember('bounds', kinds) )
    make_bounds( aligned_samples_p, aligned_binned_p, unified_filename, params );
  end
  
  if ( ismember('eye_mmv_fixations', kinds) )
    make_fixations( 'eye_mmv_fixations', aligned_samples_p, aligned_binned_p, unified_filename, params );
  end
  
  if ( ismember('arduino_fixations', kinds) )
    make_fixations( 'arduino_fixations', aligned_samples_p, aligned_binned_p, unified_filename, params );
  end
end

end

function make_bounds(aligned_samples_p, aligned_binned_p, unified_filename, params)

import shared_utils.io.fload;
import shared_utils.vector.slidebin;

output_p = fullfile( aligned_binned_p, 'bounds' );
output_filename = fullfile( output_p, unified_filename );

if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
  return
end

try
  bounds_file = fload( fullfile(aligned_samples_p, 'bounds', unified_filename) );
catch err
  print_fail_warn( unified_filename, err.message );
  return
end

monk_ids = intersect( fieldnames(bounds_file), {'m1', 'm2'} );

binned_bounds_file = bounds_file;
binned_bounds_file.params = params;

for i = 1:numel(monk_ids)
  monk_id = monk_ids{i};
  
  bounds = bounds_file.(monk_id);
  
  roi_names = keys( bounds );
  binned_bounds = containers.Map();
  
  for j = 1:numel(roi_names)
    ib = bounds(roi_names{j});
    
    ib = cellfun( @any, slidebin(ib, params.window_size, params.step_size, params.discard_uneven) );
    
    binned_bounds(roi_names{j}) = ib;
  end
  
  binned_bounds_file.(monk_id) = binned_bounds;
end

shared_utils.io.require_dir( output_p );
shared_utils.io.psave( output_filename, binned_bounds_file, 'binned_bounds_file' );

end

function make_fixations(kind, aligned_samples_p, aligned_binned_p, unified_filename, params)

import shared_utils.io.fload;
import shared_utils.vector.slidebin;

output_p = fullfile( aligned_binned_p, kind );
output_filename = fullfile( output_p, unified_filename );

if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
  return
end

try
  fixations_file = fload( fullfile(aligned_samples_p, kind, unified_filename) );
catch err
  print_fail_warn( unified_filename, err.message );
  return
end

monk_ids = intersect( fieldnames(fixations_file), {'m1', 'm2'} );

binned_fixations_file = fixations_file;
binned_fixations_file.params = params;

for i = 1:numel(monk_ids)
  monk_id = monk_ids{i};
  
  is_fix = fixations_file.(monk_id);
  is_fix = cellfun( @any, slidebin(is_fix, params.window_size, params.step_size, params.discard_uneven) );
 
  binned_fixations_file.(monk_id) = is_fix;
end

shared_utils.io.require_dir( output_p );
shared_utils.io.psave( output_filename, binned_fixations_file, 'binned_fixations_file' );

end

function make_position(aligned_samples_p, aligned_binned_p, unified_filename, params)

import shared_utils.io.fload;
import shared_utils.vector.slidebin;

output_p = fullfile( aligned_binned_p, 'position' );
output_filename = fullfile( output_p, unified_filename );

if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
  return
end

try
  pos_file = fload( fullfile(aligned_samples_p, 'position', unified_filename) );
catch err
  print_fail_warn( unified_filename, err.message );
  return
end

monk_ids = intersect( fieldnames(pos_file), {'m1', 'm2'} );

binned_pos_file = pos_file;
binned_pos_file.params = params;

for i = 1:numel(monk_ids)
  monk_id = monk_ids{i};
  
  pos = pos_file.(monk_id);
  
  x = pos(1, :);
  y = pos(2, :);
  
  binned_x = cellfun( @nanmean, slidebin(x, params.window_size, params.step_size, params.discard_uneven) );
  binned_y = cellfun( @nanmean, slidebin(y, params.window_size, params.step_size, params.discard_uneven) );
 
  binned_pos_file.(monk_id) = [ binned_x(:)'; binned_y(:)' ];
end

shared_utils.io.require_dir( output_p );
shared_utils.io.psave( output_filename, binned_pos_file, 'binned_pos_file' );

end

function make_time(aligned_binned_p, time_file, params)

import shared_utils.vector.slidebin;

ws = params.window_size;
ss = params.step_size;
discard = params.discard_uneven;

output_p = fullfile( aligned_binned_p, 'time' );
output_filename = fullfile( output_p, time_file.unified_filename );

if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
  return;
end

binned_time_file = time_file;
binned_time_file.params = params;

binned_time_file.t = cellfun( @median, slidebin(time_file.t, ws, ss, discard) );

shared_utils.io.require_dir( output_p );
shared_utils.io.psave( output_filename, binned_time_file, 'binned_time_file' );

end

function print_fail_warn(un_file, msg)
warning( '"%s" failed: %s', un_file, msg );
end

function d = get_default_kinds()
d = { 'time', 'position', 'bounds', 'eye_mmv_fixations', 'arduino_fixations' };
end