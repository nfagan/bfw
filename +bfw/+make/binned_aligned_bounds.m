function binned_bounds_file = binned_aligned_bounds(files, varargin)

%   BINNED_ALIGNED_BOUNDS -- Create binned aligned bounds file.
%
%     See also bfw.make.help
%
%     IN:
%       - `files` (containers.Map, struct)
%       - `params` (struct)
%     FILES:
%       - 'bounds'
%     OUT:
%       - `binned_bounds_file` (struct)

import shared_utils.vector.slidebin;

defaults = bfw.make.defaults.binned_aligned_samples();
params = shared_utils.general.parsestruct( defaults, varargin );

bfw.validatefiles( files, 'bounds' );
bounds_file = shared_utils.general.get( files, 'bounds' );

monk_ids = intersect( fieldnames(bounds_file), {'m1', 'm2'} );

binned_bounds_file = bounds_file;
binned_bounds_file.params = params;

for i = 1:numel(monk_ids)
  monk_id = monk_ids{i};
  
  bounds = bounds_file.(monk_id);
  
  roi_names = keys( bounds );
  binned_bounds = containers.Map();
  
  for j = 1:numel(roi_names)
    ib = bounds(roi_names{j});
    
    ib = cellfun( @any, slidebin(ib, params.window_size, params.step_size, params.discard_uneven) );
    
    binned_bounds(roi_names{j}) = ib;
  end
  
  binned_bounds_file.(monk_id) = binned_bounds;
end

end