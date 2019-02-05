function files = files_containing(files, cont)

if ( nargin < 2 ), cont = {}; end
if ( isempty(cont) ), return; end

files = shared_utils.cell.containing( files, cont );

end