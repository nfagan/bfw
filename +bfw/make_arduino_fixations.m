function make_arduino_fixations(varargin)

ff = @fullfile;

defaults = bfw.get_common_make_defaults();
defaults.threshold = 20;
defaults.n_samples = 4;
defaults.update_interval = 1;

params = bfw.parsestruct( defaults, varargin );

conf = params.config;

isd = params.input_subdir;
osd = params.output_subdir;

aligned_p = bfw.gid( ff('aligned', isd), conf );
unified_p = bfw.gid( ff('unified', isd), conf );
output_p = bfw.gid( ff('fixations', osd), conf );

aligned_mats = bfw.require_intermediate_mats( params.files, aligned_p, params.files_containing );

ui = params.update_interval;
thresh = params.threshold;
nsamp = params.n_samples;

parfor i = 1:numel(aligned_mats)

  fprintf( '\n %d of %d', i, numel(aligned_mats) );
  
  aligned_file = shared_utils.io.fload( aligned_mats{i} );
  
  un_filename = aligned_file.m1.unified_filename;
  
  unified_file = shared_utils.io.fload( fullfile(unified_p, un_filename) );
  
  output_filename = fullfile( output_p, un_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  monks = { 'm1', 'm2' };
  
  fix_struct = struct();
  fix_struct.unified_filename = unified_file.m1.unified_filename;
  fix_struct.params = params;
  
  for j = 1:numel(monks)    
    monk = monks{j};
    
    if ( ~isfield(aligned_file, monk) ), continue; end
    
    dispersion = bfw.fixation.Dispersion( thresh, nsamp, ui );
    
    pos = aligned_file.(monk).position;
    time = aligned_file.(monk).time;
    
    %   repositories/eyelink/eye_mmv
    is_fix = dispersion.detect( pos(1, :), pos(2, :) );
    
    [starts, lengths] = shared_utils.logical.find_all_starts( is_fix );
    
    stops = starts + lengths - 1;
    
    fix_struct.(monk).time = time;
    fix_struct.(monk).is_fixation = is_fix;
    fix_struct.(monk).start_indices = starts;
    fix_struct.(monk).stop_indices = stops;
  end
  
  shared_utils.io.require_dir( output_p );
  
  do_save( output_filename, fix_struct );
end

end

function do_save( filepath, fix_struct )

save( filepath, 'fix_struct' );

end