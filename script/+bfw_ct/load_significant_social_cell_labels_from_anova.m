function l = load_significant_social_cell_labels_from_anova(conf)

if ( nargin < 1 )
  conf = bfw.config.load();
end

load_file = fullfile( bfw.dataroot(conf), 'analyses', 'anova_class' ...
  , 'sig_labels', 'sig_soc_labels.mat' );

l = shared_utils.io.fload( load_file );

end