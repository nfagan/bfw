function ids = load_nested_anova_significant_cell_ids(subdirs, conf)

if ( nargin < 2 || isempty(conf) )
  conf = bfw.config.load();
end

file_path = fullfile( bfw.dataroot(conf), 'analyses', 'cell_type_classification' ...
  , subdirs{:}, 'significant_social_cell_ids.mat' );

ids = shared_utils.io.fload( file_path );

end