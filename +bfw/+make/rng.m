function rng_file = rng(files)

%   RNG -- Create rng file.
%
%     Note that this function should not be called in parallel.
%
%     See also bfw.make.help
%
%     IN:
%       - `files` (containers.Map, struct)
%     FILES:
%       - 'unified'
%     OUT:
%       - `rng_file` (struct)

bfw.validatefiles( files, 'unified' );

un_file = shared_utils.general.get( files, 'unified' );
unified_filename = bfw.try_get_unified_filename( un_file );

s = rng();
  
rng_file = struct();
rng_file.state = s;
rng_file.unified_filename = unified_filename;

end