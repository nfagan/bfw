function binned_time_file = binned_aligned_time(files, varargin)

%   BINNED_ALIGNED_TIME -- Create binned aligned time file.
%
%     See also bfw.make.help
%
%     IN:
%       - `files` (containers.Map, struct)
%       - `params` (struct)
%     FILES:
%       - 'time'
%     OUT:
%       - `binned_time_file` (struct)

import shared_utils.vector.slidebin;

bfw.validatefiles( files, 'time' );

time_file = shared_utils.general.get( files, 'time' );

defaults = bfw.make.defaults.binned_aligned_samples();
params = bfw.parsestruct( defaults, varargin );

ws = params.window_size;
ss = params.step_size;
discard = params.discard_uneven;

binned_time_file = time_file;
binned_time_file.params = params;

binned_time_file.t = cellfun( @median, slidebin(time_file.t, ws, ss, discard) );

end
