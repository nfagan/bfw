function aligned_position_file = aligned_position(files, params)

%   ALIGNED_POSITION -- Create aligned gaze position file.
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

end