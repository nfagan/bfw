function const = constants()

%   CONSTANTS -- Get constants used to define the config file structure.

const = struct();

config_folder = fileparts( which(sprintf('bfw.config.%s', mfilename)) );

const.config_filename = 'config.mat';
const.config_id = 'BFW__IS_CONFIG__';
const.config_folder = config_folder;

end