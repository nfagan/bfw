function files = filter_files(files, containing, not_containing)

%   FILTER_FILES -- Filter cell array of filenames.
%
%     f = bfw.filter_files( files, containing ); returns the subset of
%     `files` that contain any of the sub-strings in `containing`.
%
%     f = bfw.filter_files( ..., not_containing ); further retains the
%     subset of `files` that contain none of the sub-strings in
%     `not_containing`.
%
%     See also bfw.make.help

if ( nargin < 3 ), not_containing = {}; end
if ( nargin < 2 ), containing = {}; end

files = bfw.files_containing( bfw.files_not_containing(files, not_containing), containing );

end