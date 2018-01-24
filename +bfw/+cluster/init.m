function init(conf)

%   INIT -- Prepare to run a remote job.
%
%     IN:
%       - `conf` (struct) |OPTIONAL| -- config file.

if ( nargin == 0 ), conf = bfw.config.load(); end
if ( ~conf.CLUSTER.use_cluster ), return; end

%   ensure the saved config file has all the required fields.
bfw.util.assertions.assert__is_config( conf );
%   start the parpool if not already started
bfw.cluster.require_parpool();
bfw.add_depends();

end