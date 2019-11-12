function p = base_load_path(extend_with, conf)

if ( nargin < 1 )
  extend_with = {};
end

if ( nargin < 2 )
  conf = bfw.config.load();
end

p = fullfile( bfw.dataroot(conf), 'analyses', 'cell_type_classification', extend_with{:} );

end