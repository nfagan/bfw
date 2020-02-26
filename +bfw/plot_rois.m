function hs = plot_rois(rects, roi_names, varargin)

defaults = struct();
defaults.color_func = @hot;
defaults.ax = gca();
params = bfw.parsestruct( defaults, varargin );

if ( nargin < 2 || isempty(roi_names) ), roi_names = keys( rects ); end
roi_names = cellstr( roi_names );

hs = gobjects( numel(roi_names), 1 );
ax = params.ax;

colors = params.color_func( numel(roi_names) );

for i = 1:numel(roi_names)
  roi_name = roi_names{i};
  
  assert( isKey(rects, roi_name), 'Reference to non-existent roi: "%s".', roi_name );
  
  hs(i) = shared_utils.plot.rect( rects(roi_name), ax );
  set( hs(i), 'edgecolor', colors(i, :) );
end

legend( strrep(roi_names, '_', ' ') );

end