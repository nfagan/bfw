function p = get_intermediate_directory(kind, conf)

import shared_utils.assertions.*;

assert__isa( kind, 'char' );

if ( nargin < 2 || isempty(conf) )
  conf = bfw.config.load();
else
  bfw.util.assertions.assert__is_config( conf );
end

data_p = conf.PATHS.data_root;

p = fullfile( data_p, 'intermediates', kind );

end