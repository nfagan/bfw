function aligned_bounds_file = aligned_bounds(files, params)

%   ALIGNED_BOUNDS -- Create aligned bounds file.
%
%     See also bfw.make.help
%
%     IN:
%       - `files` (containers.Map, struct)
%       - `params` (struct)
%     FILES:
%       - 'aligned_raw_indices'
%       - 'raw_bounds'
%     OUT:
%       - `pos_file` (struct)

bfw.validatefiles( files, {'aligned_raw_indices', 'raw_bounds'} );

indices_file = shared_utils.general.get( files, 'aligned_raw_indices' );
bounds_file = shared_utils.general.get( files, 'raw_bounds' );

unified_filename = bfw.try_get_unified_filename( indices_file );

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

end