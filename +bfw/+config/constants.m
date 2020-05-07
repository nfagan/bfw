% @T import mt.base
% @T import bfw.types.config
% @T :: [bfw.ConfigConstants] = ()
function const = constants()

%   CONSTANTS -- Get constants used to define the config file structure.

config_folder = fileparts( which(sprintf('bfw.config.%s', mfilename)) );

% @T constructor
const = struct( ...
  'config_filename',  'config.mat' ...
  , 'config_id',      'BFW__IS_CONFIG__' ...
  , 'config_folder',  config_folder ...
);

end