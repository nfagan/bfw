function init(conf)

%   INIT -- Prepare to run a remote job.
%
%     IN:
%       - `conf` (struct) |OPTIONAL| -- config file.

if ( nargin == 0 ), conf = bfw.config.load(); end

bfw.util.assertions.assert__is_config( conf );

if ( ~conf.CLUSTER.use_cluster ), return; end

%   ensure the saved config file has all the required fields.
bfw.util.assertions.assert__config_up_to_date( conf );

%   start the parpool if not already started
bfw.cluster.require_parpool();

%   add dependencies to the path
bfw.add_depends();

end