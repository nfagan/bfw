function ls_intermediates(subdir, conf)

%   LS_INTERMEDIATES -- List intermediate files / folders.
%
%     bfw.ls_intermediates prints the list of existing intermediate
%     subdirectories.
%
%     bfw.ls_intermediates( subdirectory ) prints the contents of the
%     intermediate `subdirectory`.
%
%     bfw.ls_intermediates( ..., conf ) uses the config file `conf` to
%     generate absolute paths, instead of the saved config file.
%
%     See also bfw.load_make_ready

if ( nargin < 1 ), subdir = ''; end
if ( nargin < 2 ), conf = bfw.config.load(); end

full_path = bfw.get_intermediate_directory( subdir, conf );

% cmd = sprintf( '!ls "%s"', full_path );
ls( full_path );

% eval( cmd );

end