% @T import bfw.types.config
% @T import mt.base
% @T :: [bfw.Config] = (logical)
function conf = create(do_save)

%   CREATE -- Create the config file. 
%
%     conf = bfw.config.create(); generates and returns the default config 
%     file `conf`, a struct.
%
%     conf = bfw.config.create( true ); additionally saves `conf`.
%
%     See also bfw.config.load

if ( nargin < 1 ), do_save = false; end

%   PATHS
% @T constructor
PATHS = struct( ...
    'data_root', '' ...
  , 'repositories', '' ...
  , 'plots', '' ...
  , 'mount', '' ...
);

%   DEPENDENCIES
% @T constructor
DEPENDS = struct( ...
  'repositories', {{'shared_utils', 'spike_helpers', 'plexon' ...
  , 'jsonlab-1.5', 'chronux_2_11', 'dsp', 'global'}} ...
  , 'classes', {{ 'Edf2Mat' }} ...
  , 'others', {{''}} ...
);

%   CLUSTER
% @T constructor
CLUSTER = struct( 'use_cluster', false );

%   EXPORT
% @T constructor
conf = struct( ...
  'BFW__IS_CONFIG__', true ...
  , 'PATHS', PATHS ...
  , 'DEPENDS', DEPENDS ...
  , 'CLUSTER', CLUSTER ...
);

if ( do_save )
  bfw.config.save( conf );
end

end