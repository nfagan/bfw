function assert__config_up_to_date(conf)

%   ASSERT__CONFIG_UP_TO_DATE -- Ensure the saved config file is
%     up-to-date.
%
%     IN:
%       - `conf` (struct) |OPTIONAL|

if ( nargin < 1 ), conf = bfw.config.load(); end

does_need_update = bfw.config.needs_update( conf );

assert( ~does_need_update, ['The saved config file is missing some fields' ...
  , ' that are defined in dsp2.config.create(). Use dsp2.config.diff()' ...
  , ' to see which fields are missing.'] );

end