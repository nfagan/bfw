function conf = create(do_save)

%   CREATE -- Create the config file. 
%
%     Define editable properties of the config file here.
%
%     IN:
%       - `do_save` (logical) -- Indicate whether to save the created
%         config file. Default is `false`

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