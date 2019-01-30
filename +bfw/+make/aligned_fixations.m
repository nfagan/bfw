function aligned_fixations_file = aligned_fixations(files, varargin)

%   ALIGNED_FIXATIONS -- Create aligned fixations file.
%
%     bfw.make.aligned_fixations( files, 'fixations_subdir', subdir ); aligns
%     fixations loaded from the subdirectory `subdir`. `subdir` must be a
%     key of `files`, and will generally be one of 'raw_arduino_fixations'
%     or 'raw_eye_mmv_fixations'
%
%     See also bfw.make.help
%
%     IN:
%       - `files` (containers.Map, struct)
%       - `params` (struct)
%     FILES:
%       - 'aligned_raw_indices'
%       - <fixations_subdir>
%     OUT:
%       - `aligned_fixations_file` (struct)

defaults = bfw.make.defaults.aligned_fixations();
params = bfw.parsestruct( defaults, varargin );

fixations_subdir = params.fixations_subdir;

bfw.validatefiles( files, {'aligned_raw_indices', fixations_subdir} );

indices_file = shared_utils.general.get( files, 'aligned_raw_indices' );
fixations_file = shared_utils.general.get( files, fixations_subdir );

unified_filename = bfw.try_get_unified_filename( indices_file );

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

end