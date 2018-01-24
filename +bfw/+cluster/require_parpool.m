function p = require_parpool()

%   REQUIRE_PARPOOL -- Ensure a parpool is running.
%
%     OUT:
%       - `p` (parallel.Pool)

p = gcp( 'nocreate' );
if ( ~isempty(p) ), return; end
p = parpool( feature('NumCores') );
p.IdleTimeout = Inf;

end