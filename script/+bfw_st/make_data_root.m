function p = make_data_root(conf)

if ( nargin < 1 || isempty(conf) )
  conf = bfw.config.load();
else
  bfw.util.assertions.assert__is_config( conf );
end

p = fullfile( conf.PATHS.mount, bfw_stim_task_data_root() );

end