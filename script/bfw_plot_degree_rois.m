%%  based on spiking activity

bin_dir = '100_bins';
fix_grad_p = fullfile( bfw.dataroot(), 'analyses', 'fixation_position_gradient' );
fix_pos_p = fullfile( fix_grad_p, bin_dir );
spatial_outs = shared_utils.io.fload( fullfile(fix_pos_p, 'spatial_outs.mat') );

%%

rois = bfw_gather_rois();

%%

do_save = false;
save_p = fullfile( bfw.dataroot, 'plots/rois', dsp3.datedir );

mask_func = @(l, m) pipe(m ...
  , @(m) find(l, 'm1', m) ...
  , @(m) find(l, {'eyes_nf', 'right_nonsocial_object', 'face'}, m) ...
  , @(m) find(l, 'free_viewing', m) ...
  , @(m) find(l, ref(combs(l, 'session', m), '()', 9), m) ...
);

mask = mask_func( rois.labels, rowmask(rois.labels) );
rects = rois.rects(mask, :);
rect_labels = prune(rois.labels(mask));

[rects, ind] = unique( rects, 'rows' );
rect_labels = prune( rect_labels(ind) );

[roi_labels, roi_I] = keepeach( rect_labels', 'roi' );
roi_rects = nan( numel(roi_I), 4 );

for i = 1:numel(roi_I)
  roi_ind = roi_I{i};
  mins = min( rects(roi_ind, [1, 2]), [], 1 );
  maxs = max( rects(roi_ind, [3, 4]), [], 1 );
  roi_rects(i, :) = [ mins, maxs ];
end

%

monitor_info = bfw_default_monitor_info();
deg_roi_rects = roi_rects;
invert_y = true;

for i = 1:numel(deg_roi_rects)
  deg_roi_rects(i) = hwwa.px2deg( ...
    roi_rects(i), monitor_info.height, monitor_info.distance, monitor_info.vertical_resolution );
end

face_ind = find( roi_labels, 'face' );
obj_ind = find( roi_labels, 'right_nonsocial_object' );

face_center = shared_utils.rect.center( deg_roi_rects(face_ind, :) );
obj_center = shared_utils.rect.center( deg_roi_rects(obj_ind, :) );

dist_to_center = norm( obj_center - face_center );

for i = 1:size(deg_roi_rects, 1)
  deg_roi_rects(i, [1, 3]) = deg_roi_rects(i, [1, 3]) - face_center(1);
  deg_roi_rects(i, [2, 4]) = deg_roi_rects(i, [2, 4]) - face_center(2);
end

if ( invert_y )
  deg_roi_rects(:, [2, 4]) = -deg_roi_rects(:, [2, 4]);
  deg_roi_rects(:, [2, 4]) = deg_roi_rects(:, [4, 2]);
end

ax = gca();
cla( ax );
hold( ax, 'on' );

for i = 1:size(deg_roi_rects, 1)
  h = shared_utils.plot.rect( deg_roi_rects(i, :), ax );
end

xlims = get( ax, 'xlim' );
ylims = get( ax, 'ylim' );
lim = [ min([xlims(:); ylims(:)]), max([xlims(:); ylims(:)]) ];
xlim( ax, lim );
ylim( ax, lim );
axis( ax, 'square' );
ylabel( ax, 'DVA' );
xlabel( ax, 'DVA' );

if ( do_save )
  dsp3.req_savefig( gcf, save_p, roi_labels, 'roi' );
end

%%

custom_rois = containers.Map();
custom_roi_names = { 'eyes_nf', 'face', 'right_nonsocial_object' };
deg_limits = [-20, 20];

for i = 1:numel(custom_roi_names)  
  roi_ind = find( spatial_outs.labels, custom_roi_names{i} );
  rois = spatial_outs.relative_rois(roi_ind, :);
  frac_rois = spatial_outs.fractional_rois(roi_ind, :);
  
  ws = shared_utils.rect.width( frac_rois );
  hs = shared_utils.rect.height( frac_rois );
  areas = ws .* hs;
  [~, max_ind] = max( areas );
  
  mins = min( rois(:, [1, 2]), [], 1 );
  maxs = max( rois(:, [3, 4]), [], 1 );
  ws = shared_utils.rect.width( rois );
  hs = shared_utils.rect.height( rois );
  areas = ws .* hs;
  [~, largest_ind] = max( areas );
  union_roi = [ mins, maxs ];
  largest_roi = rois(largest_ind, :);
  assert( isequal(union_roi, largest_roi) );
  
  custom_rois(custom_roi_names{i}) = frac_rois(max_ind, :);
end