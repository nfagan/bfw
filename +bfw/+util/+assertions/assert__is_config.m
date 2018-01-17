function assert__is_config(conf)

%   ASSERT__IS_CONFIG -- Ensure input is a config file.

const = bfw.config.constants();
assert( isa(conf, 'struct'), 'Config file must be a struct; was a ''%s''.', class(conf) );
assert( isfield(conf, const.config_id) ...
  , 'Input is lacking the config file identifier ''%s''.', const.config_id );

end