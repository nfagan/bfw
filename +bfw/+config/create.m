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
PATHS.data_root = '/Volumes/My Passport/NICK/Chang Lab 2016/brains/free_viewing';
PATHS.repositories = '/Volumes/My Passport/NICK/Chang Lab 2016/repositories';

%   DEPENDENCIES
DEPENDS = struct();
DEPENDS.repositories = { 'shared_utils', 'spike_helpers', 'plexon' };

%   EXPORT
conf.PATHS = PATHS;
conf.DEPENDS = DEPENDS;

if ( do_save )
  bfw.config.save( conf );
end

end