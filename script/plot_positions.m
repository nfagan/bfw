conf = bfw.config.load();

p = bfw.get_intermediate_directory( 'bounds' );

bound_mats = shared_utils.io.find( p, '.mat' );
all_bounds = cellfun( @shared_utils.io.fload, bound_mats );

un_dir = bfw.get_intermediate_directory( 'unified' );

metas = arrayfun( @(x) shared_utils.io.fload(fullfile(un_dir, x.m1.unified_filename)), all_bounds );

%%

conditions = true( size(metas) );

conditions = conditions & arrayfun(@(x) strcmp(x.m1.mat_directory_name, '011618'), metas);
conditions = conditions & arrayfun(@(x) x.m1.mat_index == 2, metas);

filtered_bounds = all_bounds( conditions );

colors = containers.Map();
colors('face') = 'r';
colors('eyes') = 'b';

figure(1); clf();

marker_size = 0.2;

for i = 1:numel(filtered_bounds)
  
  bounds = filtered_bounds(i);
  meta = metas(i);
  
  aligned = shared_utils.io.fload( fullfile(bfw.get_intermediate_directory('aligned') ...
    , bounds.m1.aligned_filename) );
  
  monks = fieldnames( bounds );
  
  for j = 1:numel(monks)
    position = aligned.(monks{j}).position;
    current = bounds.(monks{j});
%     rois = current.bounds.keys();
    rois = { 'face', 'eyes' };
    
    subplot( 2, 1, j ); hold on;
    
    plot( position(1, :), position(2, :), 'k*', 'markersize', marker_size ); hold on;
    
    for k = 1:numel(rois)
      bound = current.bounds(rois{k});
      color = colors(rois{k});
      plot( position(1, bound), position(2, bound), color, 'markersize', marker_size ); hold on;
    end
  end
end