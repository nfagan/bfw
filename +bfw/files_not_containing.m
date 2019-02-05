function files = files_not_containing(files, cont)

if ( nargin < 2 ), cont = {}; end
if ( isempty(cont) ), return; end

files(shared_utils.cell.contains(files, cont)) = [];

end