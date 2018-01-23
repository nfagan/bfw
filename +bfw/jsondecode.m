function out = jsondecode(filename)

%   JSONDECODE -- Decode json data into a matlab struct.
%
%     IN:
%       - `filename` (char)

shared_utils.assertions.assert__isa( filename, 'char' );

if ( ~isempty(which('jsondecode')) )
  out = jsondecode( fileread(filename) );
  return;
end

out = loadjson( filename );

end