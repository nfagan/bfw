function make_eye_mmv_fixations(varargin)

ff = @fullfile;

defaults = bfw.get_common_make_defaults();
defaults.min_duration = 0.01;
defaults.t1 = 30;
defaults.t2 = 15;

params = bfw.parsestruct( defaults, varargin );

conf = params.config;

isd = params.input_subdir;
osd = params.output_subdir;

aligned_p = bfw.gid( ff('aligned', isd), conf );
unified_p = bfw.gid( ff('unified', isd), conf );
output_p = bfw.gid( ff('fixations', osd), conf );

aligned_mats = bfw.require_intermediate_mats( params.files, aligned_p, params.files_containing );

t1 = params.t1;
t2 = params.t2;
min_duration = params.min_duration;

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
    
    pos = aligned_file.(monk).position;
    time = aligned_file.(monk).time;
    
    %   repositories/eyelink/eye_mmv
    is_fix = is_fixation( pos, time(:)', t1, t2, min_duration );
    is_fix = logical( is_fix );
    is_fix = is_fix(1:numel(time))';
    
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