function files = find_intermediates(kind, conf)

%   FIND_INTERMEDIATES -- Find intermediate .mat files.
%
%     files = bfw.find_intermediates( kind ); returns a cell array of
%     absolute paths to .mat files in the intermediate directory given by
%     `kind`. The absolute path to `kind` is determined by the saved config
%     file.
%
%     files = bfw.find_intermediates( ..., conf ) uses `conf` to generate
%     the absolute path to `kind`, instead of the saved config file.
%
%     See also shared_utils.io.find

if ( nargin < 2 || isempty(conf) )
  conf = bfw.config.load();
end

files = shared_utils.io.findmat( bfw.get_intermediate_directory(kind, conf) );

end