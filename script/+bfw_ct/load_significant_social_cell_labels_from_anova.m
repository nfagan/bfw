function l = load_significant_social_cell_labels_from_anova(conf, use_remade)

if ( nargin < 1 )
  conf = bfw.config.load();
end
if ( nargin < 2 )
  use_remade = false;
end

if ( use_remade )
  filename = 'sig_soc_labels_remade.mat';
else
  filename = 'sig_soc_labels.mat';
end

load_file = fullfile( bfw.dataroot(conf), 'analyses', 'anova_class' ...
  , 'sig_labels', filename );

l = shared_utils.io.fload( load_file );

end