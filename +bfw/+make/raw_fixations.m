function fix_file = raw_fixations(files, is_fix_func, varargin)

%   RAW_FIXATIONS -- Create fixations file.
%
%     See also bfw.make.help, bfw.make_raw_fixations,
%       bfw.make.defaults.raw_fixations
%
%     IN:
%       - `files` (containers.Map, struct)
%       - `is_fix_func` (function_handle)
%     FILES:
%       - 'edf_raw_samples'
%     OUT:
%       - `events_file` (struct)

bfw.validatefiles( files, 'edf_raw_samples' );

defaults = bfw.make.defaults.raw_fixations();
params = bfw.parsestruct( defaults, varargin );

samples_file = shared_utils.general.get( files, 'edf_raw_samples' );
unified_filename = bfw.try_get_unified_filename( samples_file );

validateattributes( is_fix_func, {'function_handle'}, {}, mfilename, 'is_fix_func' );

monks = { 'm1', 'm2' };

fix_file = struct();
fix_file.unified_filename = unified_filename;
fix_file.params = params;

for j = 1:numel(monks)    
  monk = monks{j};

  if ( ~isfield(samples_file, monk) ), continue; end

  x = samples_file.(monk).x;
  y = samples_file.(monk).y;

  time = samples_file.(monk).t;

  is_fix = is_fix_func( x, y, time, params );

  [starts, lengths] = shared_utils.logical.find_all_starts( is_fix );

  stops = starts + lengths - 1;

  fix_file.(monk).time = time;
  fix_file.(monk).is_fixation = is_fix;
  fix_file.(monk).start_indices = starts;
  fix_file.(monk).stop_indices = stops;
end

end