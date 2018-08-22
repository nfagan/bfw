function p = get_intermediate_directory(kind, conf)

%   GET_INTERMEDIATE_DIRECTORY -- Get full path to intermediate folder.
%
%     p = get_intermediate_directory( 'rois' ) returns the full path to the
%     intermediate directory 'rois'.
%
%     p = get_intermediate_directory( .., conf ) uses the config file
%     `conf` to create the full path, instead of the saved config file.
%
%     IN:
%       - `kind` (char)
%       - `conf` (struct)
%     OUT:
%       - `p` (cell array of strings, char)

import shared_utils.assertions.*;

if ( nargin < 2 || isempty(conf) )
  conf = bfw.config.load();
else
  bfw.util.assertions.assert__is_config( conf );
end

data_p = conf.PATHS.data_root;

p = shared_utils.io.fullfiles( data_p, 'intermediates', kind );

if ( isa(kind, 'char') ), p = char( p ); end

end