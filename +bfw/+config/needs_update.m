function does_need_update = needs_update(conf)

%   NEEDS_UPDATE -- Check whether the saved config file has all the same
%     fields as the file that would be created by dsp2.config.create().
%
%     IN:
%       - `conf` (struct) |OPTIONAL| -- Config file to check.
%     OUT:
%       - `does_need_update` (logical)

if ( nargin < 1 ), conf = bfw.config.load(); end

does_need_update = true;
should_display = false;
missing = bfw.config.diff( conf, should_display );

if ( numel(missing) == 0 ), does_need_update = false; end

end