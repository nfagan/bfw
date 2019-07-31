function plot_p = stim_summary_plot_p(params, varargin)

plot_p = fullfile( bfw.dataroot(params.config), 'plots', 'stim_summary' ...
  , dsp3.datedir, params.base_subdir, varargin{:} );

end