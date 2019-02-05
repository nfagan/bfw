function set_skip_existing_files(runner, output_directory, ext)

%   SET_SKIP_EXISTING_FILES -- Configure the runner to skip files that
%     already exist in the output folder.
%
%     bfw.set_skip_existing_files( runner, output_directory ); configures
%     the `runner` to avoid processing mat-file identifiers that are already
%     present in `output_directory`. If `output_directory` does not exist,
%     this function has no effect.
%
%     bfw.set_skip_existing_files( ..., extension ) uses `extension` to
%     look for files in `output_directory`, instead of '.mat'.
%
%     See also bfw.get_looped_make_runner, bfw.make.help,
%     shared_utils.pipeline.LoopedMakeRunner

if ( nargin < 3 ), ext = '.mat'; end

validateattributes( runner, {'shared_utils.pipeline.LoopedMakeRunner'} ...
  , {'scalar'}, mfilename, 'runner' );
validateattributes( output_directory, {'string', 'char'}, {'scalartext'} ...
  , mfilename, 'output_directory' );
validateattributes( ext, {'string', 'char'}, {'scalartext'} ...
  , mfilename, 'extension' );

output_directory = char( output_directory );

if ( ~shared_utils.io.dexists(output_directory) )
  return
end

try
  current_files = shared_utils.io.dirnames( output_directory, ext );
catch err
  return
end

% First filter the files according to the current filter function. Then, 
% of the subset that remain, exclude those that contain any of `current_files`.

filter_func = runner.filter_files_func;
runner.filter_files_func = @(x) bfw.filter_files( filter_func(x), {}, current_files );

end