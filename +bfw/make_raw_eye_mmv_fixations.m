function make_raw_eye_mmv_fixations(varargin)

ff = @fullfile;

defaults = bfw.get_common_make_defaults();
defaults.min_duration = 0.01;
defaults.t1 = 30;
defaults.t2 = 15;

params = bfw.parsestruct( defaults, varargin );

conf = params.config;

isd = params.input_subdir;
osd = params.output_subdir;

samples_p = bfw.gid( ff('edf_raw_samples', isd), conf );
fixations_p = bfw.gid( ff('raw_eye_mmv_fixations', osd), conf );

mats = bfw.require_intermediate_mats( params.files, samples_p, params.files_containing );

t1 = params.t1;
t2 = params.t2;
min_duration = params.min_duration;

for i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats), mfilename );
  
  samples_file = shared_utils.io.fload( mats{i} );
  
  unified_filename = samples_file.unified_filename;
  
  output_filename = fullfile( fixations_p, unified_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  monks = { 'm1', 'm2' };
  
  fix_file = struct();
  fix_file.unified_filename = unified_filename;
  fix_file.params = params;
  
  for j = 1:numel(monks)    
    monk = monks{j};
    
    if ( ~isfield(samples_file, monk) ), continue; end
    
    x = samples_file.(monk).x;
    y = samples_file.(monk).y;
    
    pos = [ x(:)'; y(:)' ];
    time = samples_file.(monk).t;
    
    %   repositories/eyelink/eye_mmv
    is_fix = is_fixation( pos, time(:)', t1, t2, min_duration );
    is_fix = logical( is_fix );
    is_fix = is_fix(1:numel(time))';
    
    [starts, lengths] = shared_utils.logical.find_all_starts( is_fix );
    
    stops = starts + lengths - 1;
    
    fix_file.(monk).time = time;
    fix_file.(monk).is_fixation = is_fix;
    fix_file.(monk).start_indices = starts;
    fix_file.(monk).stop_indices = stops;
  end
  
  shared_utils.io.require_dir( fixations_p );
  shared_utils.io.psave( output_filename, fix_file, 'fix_file' );
end

end