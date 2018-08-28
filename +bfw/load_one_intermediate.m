function x = load_one_intermediate(kind, name, conf)

%   LOAD_ONE_INTERMEDIATE -- Load one intermediate file.
%
%     X = load_one_intermediate( INTERMEDIATE ) loads one file from the
%     intermediate directory `INTERMEDIATE`.
%
%     X = load_one_intermediate( ..., NAME ) loads one file that contains
%     the char `NAME`. If no files contain `NAME`, `X` is an empty array.
%
%     X = load_one_intermediate( ..., conf ) uses the config file `conf` to
%     generate the path to the intermediate directory, instead of the saved
%     config file.
%
%     IN:
%       - `kind` (char)
%       - `name` (char)
%       - `conf` (struct)
%     OUT:
%       - `x` (/any/)

if ( nargin < 3 || isempty(conf) ), conf = bfw.config.load(); end
if ( nargin < 2 ), name = ''; end

bfw.util.assertions.assert__is_config( conf );

intermediate_dir = bfw.get_intermediate_directory( kind, conf );

mats = shared_utils.io.find( intermediate_dir, '.mat' );

x = [];

if ( numel(mats) == 0 ), return; end

if ( isempty(name) )
  x = shared_utils.io.fload( mats{1} );
  return;
end

mats = shared_utils.cell.containing( mats, name );

if ( isempty(mats) ), return; end

x = shared_utils.io.fload( mats{1} );

end