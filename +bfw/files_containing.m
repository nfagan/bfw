function f = files_containing(files, cont)

if ( nargin < 2 ), cont = {}; end
if ( isempty(cont) ), f = files; return; end

f = shared_utils.cell.containing( files, cont );

end