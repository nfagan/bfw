function [matches, latest_version, built_version] = bfw_check_version(mex_filename)

%   BFW_CHECK_VERSION -- Check whether the built version of a mex file is up-to-date.
%
%     tf = bfw_check_version( mex_filename ); returns true if the version 
%     of the mex function given by `bfw.mex.<mex_filename>` is the latest
%     version.
%
%     [..., latest_version, built_version] returns the char vector
%     identifiers for the latest and built versions of the function,
%     respectively.
%
%     See also bfw.mex.build_single_file

vers_file = fullfile( bfw.util.get_project_folder(), 'mex', 'version', sprintf('%s_version.txt', mex_filename) );

assert( shared_utils.io.fexists(vers_file), 'Version file "%s" does not exist.', vers_file );

latest_version = fileread( vers_file );

eval( sprintf('built_version = bfw.mex.%s();', mex_filename) );

matches = isequaln( latest_version, built_version );

end