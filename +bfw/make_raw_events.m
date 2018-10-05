function make_raw_events(varargin)

import shared_utils.io.fload;

ff = @fullfile;

defaults = bfw.get_common_make_defaults();
defaults.duration = NaN;  % ms
defaults.bin_raw = true;
defaults.window_size = 10;
defaults.step_size = 10;
defaults.fixations_subdir = 'raw_eye_mmv_fixations';

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;
osd = params.output_subdir;
fsd = params.fixations_subdir;

duration = params.duration;
assert( ~isnan(duration), '"duration" cannot be nan.' );

fixations_p = bfw.gid( ff(fsd, isd), conf );
bounds_p = bfw.gid( ff('raw_bounds', isd), conf );
aligned_p = bfw.gid( ff('aligned_raw_indices', isd), conf );
events_p = bfw.gid( ff('events', osd), conf );

mats = bfw.require_intermediate_mats( params.files, bounds_p, params.files_containing );

for i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats), mfilename );
  
  bounds_file = fload( mats{i} );
  
  unified_filename = bounds_file.unified_filename;
  
  try
    fix_file = fload( fullfile(fixations_p, unified_filename) ); 
    aligned_file = fload( fullfile(aligned_p, unified_filename) );
  catch err
    print_fail_warn( unified_filename, err.message );
    continue;
  end
  
  fs = intersect( {'m1', 'm2'}, fieldnames(bounds_file) );
  
  has_multiple_fields = numel( fs ) > 1;
  
  if ( has_multiple_fields )
    
  end
  
  should_save = true;
  
  for j = 1:numel(fs)
    monk_id = fs{j};
    
    bounds = bounds_file.(monk_id).bounds;
    is_fix = fix_file.(monk_id).is_fixation;
    
    try
      exclusive_evts = find_exclusive_events( bounds, is_fix, params );
    catch err
      print_fail_warn( unified_filename, err.message );
      should_save = false;
      break;  
    end
  end
  
end

end

function evts = find_exclusive_events(bounds, is_fix, params)

d = 10;

end

function print_fail_warn(un_file, msg)
warning( '"%s" failed: %s', un_file, msg );
end