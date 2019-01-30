function files = load_make_ready(kinds, name, conf)

%   LOAD_MAKE_READY -- Load files into format expected by bfw.make.* functions.
%
%     files = bfw.load_make_ready( INTERMEDIATE_SUBFOLDERS ); returns a
%     containers.Map object `files` whose keys are the names of
%     intermediate subfolders given by `INTERMEDIATE_SUBFOLDERS`, except
%     that for multi-level subfolders (subdir/subdir2), keys will be made
%     from the inner-most subfolder.
%
%     The specific identifier used to load files is unspecified, but it 
%     will match between those files. If any of the files does not
%     exist, its entry in `files` will be the empty array ([]).
%
%     files = bfw.load_make_ready( ..., PATTERN ) uses the string
%     `PATTERN` to search for filenames to load. `PATTERN` need not be an
%     exact unified_filename.
%
%     files = bfw.load_make_ready( ..., conf ) uses `conf` to generate
%     paths to the intermediate files, instead of the saved config file.
%
%     See also bfw.make.help
%
%     EXAMPLE 1. //
%
%     % Load intermediate files in subfolders 'meta' and
%     % 'aligned_raw_samples/time'. Because 'meta' does not specify a
%     % multi-level subfolder, it will accessible in `files` as
%     % `files('meta')`. Because 'aligned_raw_samples/time' *does* specify
%     % a multi-level subfolder, it will be accessible as `files('time')`
%     files = bfw.load_make_ready( {'aligned_raw_samples/time', 'meta'} );
%
%     EXAMPLE 2. //
%
%     % Load intermediate files required by `bfw.make.raw_events`, then
%     % generate the events file from those inputs
%     intermediates = { 'aligned_raw_samples/time' ...
%       , 'aligned_raw_samples/bounds' ...
%       , 'aligned_raw_samples/eye_mmv_fixations' };
%     files = bfw.load_make_ready( intermediates );
%     bfw.make.raw_events( files, 'duration', 10 );
%
%     IN:
%       - `kinds` (cell array of strings, char)
%       - `name` (char) |OPTIONAL|
%       - `conf` (struct) |OPTIONAL|
%     OUT:
%       - `files` (containers.Map)

if ( nargin < 3 )
  conf = bfw.config.load();
end

if ( nargin == 2 && isstruct(name) )
  bfw.util.assertions.assert__is_config( name );
  conf = name;
  name = '';
end

if ( nargin < 2 )
  name = '';
end

kinds = cellstr( kinds );
files = containers.Map();

unified_filename = '';

for i = 1:numel(kinds)
  search_for = name;
  
  if ( i > 1 && ~isempty(unified_filename) )
    search_for = unified_filename;
  end
  
  file = bfw.load1( kinds{i}, search_for, conf );
  
  if ( ~isempty(file) && isempty(unified_filename) )
    try
      unified_filename = bfw.try_get_unified_filename( file );
    catch err
      warning( err.message );
    end
  end
  
  if ( isempty(file) )
    warning( 'No file found for kind: "%s" and unified filename: "%s".' ...
      , kinds{i}, search_for );
  end
  
  key = shared_utils.pipeline.LoopedMakeRunner.get_directory_name( kinds{i} );
  files(key) = file;
end

end