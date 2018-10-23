function make_raw_aligned_samples(varargin)

import shared_utils.io.fload;

ff = @fullfile;

defaults = bfw.get_common_make_defaults();
defaults.kinds = get_default_kinds();

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;
osd = params.output_subdir;

kinds = shared_utils.cell.ensure_cell( params.kinds );

try
  aligned_file_map = bfw.get_raw_aligned_intermediate_dir_map( kinds, isd, conf );
catch err
  warning( err.message );
  return;
end

indices_p = bfw.gid( ff('aligned_raw_indices', isd), conf );
aligned_p = bfw.gid( ff('aligned_raw_samples', osd), conf );

mats = bfw.require_intermediate_mats( params.files, indices_p, params.files_containing );

params.is_binned = false;

parfor i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats), mfilename );
  
  indices_file = fload( mats{i} );
  
  %   time
  if ( isKey(aligned_file_map, 'time') )
    make_time( indices_file, aligned_p, params );
  end
  
  %   position
  if ( isKey(aligned_file_map, 'position') )
    make_position( indices_file, aligned_file_map, aligned_p, params );
  end
  
  %   bounds
  if ( isKey(aligned_file_map, 'bounds') )
    make_bounds( indices_file, aligned_file_map, aligned_p, params );
  end
  
  %   eye-mmv fixations
  if ( isKey(aligned_file_map, 'eye_mmv_fixations') )
    make_fixations( 'eye_mmv_fixations', indices_file, aligned_file_map, aligned_p, params );
  end
  
  %   arduino fixations
  if ( isKey(aligned_file_map, 'arduino_fixations') )
    make_fixations( 'arduino_fixations', indices_file, aligned_file_map, aligned_p, params );
  end
end

end

function make_time(indices_file, aligned_p, params)

import shared_utils.io.fload;

unified_filename = indices_file.unified_filename;

output_p = fullfile( aligned_p, 'time' );
output_filename = fullfile( output_p, unified_filename );

if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
  return;
end

time_file = struct();
time_file.unified_filename = unified_filename;
time_file.params = params;
time_file.t = indices_file.t;

shared_utils.io.require_dir( output_p );
shared_utils.io.psave( output_filename, time_file, 'time_file' );

end

function make_position(indices_file, aligned_file_map, aligned_p, params)

import shared_utils.io.fload;

unified_filename = indices_file.unified_filename;

output_p = fullfile( aligned_p, 'position' );
output_filename = fullfile( output_p, unified_filename );

if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
  return;
end

try
  samples_file = fload( fullfile(aligned_file_map('position'), unified_filename) );
catch err
  print_fail_warn( unified_filename, err.message );
  return
end

monk_ids = intersect( {'m1', 'm2'}, fieldnames(samples_file) );

aligned_position_file = struct();
aligned_position_file.unified_filename = unified_filename;
aligned_position_file.params = params;

N = numel( indices_file.t );

for i = 1:numel(monk_ids)
  monk_id = monk_ids{i};
  
  x = samples_file.(monk_id).x;
  y = samples_file.(monk_id).y;
  
  indices = indices_file.(monk_id);
  
  current_aligned_pos = nan( 2, N );
  
  non_zero = indices > 0;
  non_zero_inds = indices(non_zero);
  
  current_aligned_pos(1, non_zero) = x(non_zero_inds);
  current_aligned_pos(2, non_zero) = y(non_zero_inds);
    
  aligned_position_file.(monk_id) = current_aligned_pos;
end

shared_utils.io.require_dir( output_p );
shared_utils.io.psave( output_filename, aligned_position_file, 'aligned_position_file' );

end

function make_bounds(indices_file, aligned_file_map, aligned_p, params)

import shared_utils.io.fload;

unified_filename = indices_file.unified_filename;

output_p = fullfile( aligned_p, 'bounds' );
output_filename = fullfile( output_p, unified_filename );

if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
  return;
end

try
  bounds_file = fload( fullfile(aligned_file_map('bounds'), unified_filename) );
catch err
  print_fail_warn( unified_filename, err.message );
  return
end

monk_ids = intersect( {'m1', 'm2'}, fieldnames(bounds_file) );

aligned_bounds_file = struct();
aligned_bounds_file.unified_filename = unified_filename;
aligned_bounds_file.params = params;

N = numel( indices_file.t );

for i = 1:numel(monk_ids)
  monk_id = monk_ids{i};
  
  bounds = bounds_file.(monk_id).bounds;
  
  indices = indices_file.(monk_id);
  
  non_zero = indices > 0;
  non_zero_inds = indices(non_zero);
  
  roi_names = keys( bounds );
  
  current_aligned_bounds = containers.Map();
  
  for j = 1:numel(roi_names)
    ib = bounds(roi_names{j});
    
    current_ib = false( 1, N );
    current_ib(non_zero) = ib(non_zero_inds);
    
    current_aligned_bounds(roi_names{j}) = current_ib;
  end
    
  aligned_bounds_file.(monk_id) = current_aligned_bounds;
end

shared_utils.io.require_dir( output_p );
shared_utils.io.psave( output_filename, aligned_bounds_file, 'aligned_bounds_file' );

end

function make_fixations(kind, indices_file, aligned_file_map, aligned_p, params)

import shared_utils.io.fload;

unified_filename = indices_file.unified_filename;

output_p = fullfile( aligned_p, kind );
output_filename = fullfile( output_p, unified_filename );

if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
  return;
end

try
  fixations_file = fload( fullfile(aligned_file_map(kind), unified_filename) );
catch err
  print_fail_warn( unified_filename, err.message );
  return
end

monk_ids = intersect( {'m1', 'm2'}, fieldnames(fixations_file) );

aligned_fixations_file = struct();
aligned_fixations_file.unified_filename = unified_filename;
aligned_fixations_file.params = params;

N = numel( indices_file.t );

for i = 1:numel(monk_ids)
  monk_id = monk_ids{i};
  
  is_fix = fixations_file.(monk_id).is_fixation;
  
  indices = indices_file.(monk_id);
  
  current_aligned_fixation = false( 1, N );
  
  non_zero = indices > 0;
  non_zero_inds = indices(non_zero);
  
  current_aligned_fixation(non_zero) = is_fix(non_zero_inds);
    
  aligned_fixations_file.(monk_id) = current_aligned_fixation;
end

shared_utils.io.require_dir( output_p );
shared_utils.io.psave( output_filename, aligned_fixations_file, 'aligned_fixations_file' );

end

function print_fail_warn(un_file, msg)
warning( '"%s" failed: %s', un_file, msg );
end

function d = get_default_kinds()
d = { 'time', 'position', 'bounds', 'eye_mmv_fixations', 'arduino_fixations' };
end