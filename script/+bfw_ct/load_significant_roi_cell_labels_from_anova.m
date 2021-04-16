function l = load_significant_roi_cell_labels_from_anova(conf, use_remade)

if ( nargin < 1 )
  conf = bfw.config.load();
end

if ( nargin < 2 )
  use_remade = true;
end

if ( use_remade )
  load_file = fullfile( bfw.dataroot(conf), 'analyses', 'anova_class' ...
    , 'sig_labels', 'sig_roi_labels_remade.mat' );
else
  load_file = fullfile( bfw.dataroot(conf), 'analyses', 'anova_class' ...
    , 'sig_labels', 'sig_roi_labels.mat' );
end

l = shared_utils.io.fload( load_file );

end