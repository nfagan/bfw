function binned_fixations_file = binned_aligned_fixations(files, varargin)

%   BINNED_ALIGNED_FIXATIONS -- Create binned aligned fixations file.
%
%     See also bfw.make.help
%
%     IN:
%       - `files` (containers.Map, struct)
%       - `params` (struct)
%     FILES:
%       - <fixations_subdir>
%     OUT:
%       - `binned_fixations_file` (struct)

import shared_utils.vector.slidebin;

defaults = bfw.make.defaults.binned_aligned_samples();
params = bfw.parsestruct( defaults, varargin );

bfw.validatefiles( files, params.fixations_subdir );

fixations_file = shared_utils.general.get( params.fixations_subdir );

monk_ids = intersect( fieldnames(fixations_file), {'m1', 'm2'} );

binned_fixations_file = fixations_file;
binned_fixations_file.params = params;

for i = 1:numel(monk_ids)
  monk_id = monk_ids{i};
  
  is_fix = fixations_file.(monk_id);
  is_fix = cellfun( @any, slidebin(is_fix, params.window_size, params.step_size, params.discard_uneven) );
 
  binned_fixations_file.(monk_id) = is_fix;
end

end
