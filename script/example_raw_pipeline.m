conf = bfw.config.load();

selector = '09042018_position_1.mat';

samples_file = bfw.load1( 'edf_raw_samples', selector, conf );
aligned_file = bfw.load1( 'aligned_raw_indices', samples_file.unified_filename, conf );
fix_file = bfw.load1( 'raw_arduino_fixations', samples_file.unified_filename, conf );
bounds_file = bfw.load1( 'raw_bounds', samples_file.unified_filename, conf );

plex_time = aligned_file.t;
N = numel( plex_time );

monk_ids = intersect( fieldnames(samples_file), {'m1', 'm2'} );

aligned_position = struct();
aligned_fix = struct();
aligned_bounds = struct();

for i = 1:numel(monk_ids)
  monk_id = monk_ids{i};
  
  x = samples_file.(monk_id).x;
  y = samples_file.(monk_id).y;
  is_fix = fix_file.(monk_id).is_fixation;
  bounds = bounds_file.(monk_id).bounds;
  
  indices = aligned_file.(monk_id);
  
  current_aligned_pos = nan( 2, N );
  current_aligned_fix = false( 1, N );
  
  non_zero = indices > 0;
  non_zero_inds = indices(non_zero);
  
  current_aligned_pos(1, non_zero) = x(non_zero_inds);
  current_aligned_pos(2, non_zero) = y(non_zero_inds);
  current_aligned_fix(non_zero) = is_fix(non_zero_inds);
  
  roi_names = keys( bounds );
  current_aligned_bounds = containers.Map();
  
  for j = 1:numel(roi_names)
    ib = bounds(roi_names{j});
    
    current_ib = false( 1, N );
    current_ib(non_zero) = ib(non_zero_inds);
    
    current_aligned_bounds(roi_names{j}) = current_ib;
  end
    
  aligned_position.(monk_id) = current_aligned_pos;
  aligned_fix.(monk_id) = current_aligned_fix;
  aligned_bounds.(monk_id) = current_aligned_bounds;
end

%%