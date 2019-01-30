function time_file = aligned_time(files, params)

%   ALIGNED_TIME -- Create aligned time file.
%
%     See also bfw.make.help
%
%     IN:
%       - `files` (containers.Map, struct)
%       - `params` (struct)
%     FILES:
%       - 'aligned_raw_indices'
%     OUT:
%       - `time_file` (struct)

bfw.validatefiles( files, 'aligned_raw_indices' );

indices_file = shared_utils.general.get( files, 'aligned_raw_indices' );
unified_filename = bfw.try_get_unified_filename( indices_file );

time_file = struct();
time_file.unified_filename = unified_filename;
time_file.params = params;
time_file.t = indices_file.t;

end