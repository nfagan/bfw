function aligned_pupil_size_file = aligned_pupil_size(files, params)

%   ALIGNED_POSITION -- Create aligned pupil size file.
%
%     See also bfw.make.help
%
%     IN:
%       - `files` (containers.Map, struct)
%       - `params` (struct)
%     FILES:
%       - 'aligned_raw_indices'
%       - 'edf_raw_samples'
%     OUT:
%       - `pos_file` (struct)

bfw.validatefiles( files, {'aligned_raw_indices', 'edf_raw_samples'} );

indices_file = shared_utils.general.get( files, 'aligned_raw_indices' );
samples_file = shared_utils.general.get( files, 'edf_raw_samples' );

unified_filename = bfw.try_get_unified_filename( indices_file );

monk_ids = intersect( {'m1', 'm2'}, fieldnames(samples_file) );

aligned_pupil_size_file = struct();
aligned_pupil_size_file.unified_filename = unified_filename;
aligned_pupil_size_file.params = params;

N = numel( indices_file.t );

for i = 1:numel(monk_ids)
  monk_id = monk_ids{i};
  ps = samples_file.(monk_id).pupil;
  indices = indices_file.(monk_id);
  
  non_zero = indices > 0;
  non_zero_inds = indices(non_zero);
  
  current_aligned_ps = nan( 1, N );
  current_aligned_ps(1, non_zero) = ps(non_zero_inds);
  aligned_pupil_size_file.(monk_id) = current_aligned_ps;
end

end