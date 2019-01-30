function binned_pos_file = binned_aligned_position(files, varargin)

%   BINNED_ALIGNED_POSITION -- Create binned aligned position file.
%
%     See also bfw.make.help
%
%     IN:
%       - `files` (containers.Map, struct)
%       - `params` (struct)
%     FILES:
%       - 'position'
%     OUT:
%       - `binned_pos_file` (struct)

import shared_utils.vector.slidebin;

defaults = bfw.make.defaults.binned_aligned_samples();
params = bfw.parsestruct( defaults, varargin );

bfw.validatefiles( files, 'position' );
pos_file = shared_utils.general.get( files, 'position' );

monk_ids = intersect( fieldnames(pos_file), {'m1', 'm2'} );

binned_pos_file = pos_file;
binned_pos_file.params = params;

ws = params.window_size;
ss = params.step_size;
discard_uneven = params.discard_uneven;

for i = 1:numel(monk_ids)
  monk_id = monk_ids{i};
  
  pos = pos_file.(monk_id);
  
  x = pos(1, :);
  y = pos(2, :);
  
  binned_x = cellfun( @nanmean, slidebin(x, ws, ss, discard_uneven) );
  binned_y = cellfun( @nanmean, slidebin(y, ws, ss, discard_uneven) );
 
  binned_pos_file.(monk_id) = [ binned_x(:)'; binned_y(:)' ];
end

end