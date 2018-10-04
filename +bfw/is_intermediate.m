function tf = is_intermediate(kind, str, conf)

%   IS_INTERMEDIATE -- True if an intermediate file is present.
%
%     tf = ... is_intermediate( KIND, STR ); returns true if `STR` is
%     contained in a filename of the intermediate directory `KIND`. `STR`
%     need not specify an exact filename.
%
%     tf = ... is_intermediate( ..., conf ); uses the config file `conf` to
%     get the full path to the intermediate directory, instead of the saved
%     config file.
%
%     IN:
%       - `kind` (char)
%       - `name` (char)
%       - `conf` (struct) |OPTIONAL|
%     OUT:
%       - `tf` (logical)

if ( nargin < 3 || isempty(conf) )
  conf = bfw.config.load(); 
else
  bfw.util.assertions.assert__is_config( conf );
end

validateattributes( kind, {'char'}, {}, mfilename, 'kind' );
validateattributes( str, {'char'}, {}, mfilename, 'str' );

intermediate_p = bfw.gid( kind, conf );

all_files = shared_utils.io.dirnames( intermediate_p, '.mat' );

tf = any( cellfun(@(x) ~isempty(strfind(x, str)), all_files) );

end