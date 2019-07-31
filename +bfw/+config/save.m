
function save(conf)

%   SAVE -- Save the config file.
%
%     bfw.config.save( conf ), where `conf` is a valid config file, saves
%     `conf`.
%
%     See also bfw.config.create, bfw.config.load

bfw.util.assertions.assert__is_config( conf );
const = bfw.config.constants();
fprintf( '\n Config file saved\n\n' );
save( fullfile(const.config_folder, const.config_filename), 'conf' );

bfw.config.load( '-clear' );

end