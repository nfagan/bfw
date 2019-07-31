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

const = bfw.config.constants();

conf = struct();

%   ID
conf.(const.config_id) = true;

%   PATHS
PATHS = struct();
PATHS.data_root = '';
PATHS.repositories = '';
PATHS.plots = '';
PATHS.mount = '';

%   DEPENDENCIES
DEPENDS = struct();
DEPENDS.repositories = { 'shared_utils', 'spike_helpers', 'plexon' ...
  , 'jsonlab-1.5', 'chronux_2_11', 'dsp', 'global' };
DEPENDS.classes = { 'Edf2Mat' };
DEPENDS.others = { '' };

%   CLUSTER

CLUSTER = struct();
CLUSTER.use_cluster = false;

%   EXPORT
conf.PATHS = PATHS;
conf.DEPENDS = DEPENDS;
conf.CLUSTER = CLUSTER;

if ( do_save )
  bfw.config.save( conf );
end

end