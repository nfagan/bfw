function bfw_check_eyelink_fixations(varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.rois = { 'face', 'left_nonsocial_object', 'right_nonsocial_object', 'screen' };

inputs = { 'aligned_raw_samples/position' ...
  , 'aligned_raw_samples/raw_eye_mmv_fixations', 'rois', 'single_origin_offsets', 'meta' };

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
loop_runner.convert_to_non_saving_with_output();

results = loop_runner.run( @main, params );

end

function status = main(files, params)

status = 0;

pos_file = shared_utils.general.get( files, 'position' );
fix_file = shared_utils.general.get( files, 'raw_eye_mmv_fixations' );
roi_file = shared_utils.general.get( files, 'rois' );
offset_file = shared_utils.general.get( files, 'single_origin_offsets' );
meta_file = shared_utils.general.get( files, 'meta' );

labels = bfw.struct2fcat( meta_file );

[fix_starts, fix_durs] = shared_utils.logical.find_all_starts( fix_file.m1 );
fix_stops = fix_starts + fix_durs - 1;

fix_x = arrayfun( @(x, y) nanmean(pos_file.m1(1, x:y)), fix_starts, fix_stops );
fix_y = arrayfun( @(x, y) nanmean(pos_file.m1(2, x:y)), fix_starts, fix_stops );

[norm_fix_x, min_x, max_x] = bfw.norm01( fix_x );
[norm_fix_y, min_y, max_y] = bfw.norm01( fix_y );
norm_fix_y = 1 - norm_fix_y;  % flip y

rects = roi_file.m1.rects;
rects('screen') = calculate_screen_rect( offset_file.m1 );

normalize_rects( rects, min_x, max_x, min_y, max_y );
plot_rois( norm_fix_x, norm_fix_y, rects, labels, params );

end

function r = calculate_screen_rect(offsets)

r = [0, 0, 1024*3, 768];
r([1, 3]) = r([1, 3]) - offsets(1);
r([2, 4]) = r([2, 4]) - offsets(2);

end

function plot_rois(fix_x, fix_y, rects, labels, params)

f = figure(1);
clf( f );
ax = gca();
cla( ax );

set( ax, 'nextplot', 'replace' );
scatter( fix_x, fix_y, 2 );
hold( ax, 'on' );

plot_rois = cellstr( params.rois );

for i = 1:numel(plot_rois)
  roi_name = plot_rois{i};
  
  hs = bfw.plot_rect_as_lines( gca, rects(roi_name) );
  set( hs, 'color', [0, 0, 0] );
  set( hs, 'linewidth', 1 );
end

titles_are = {'mat_filename', 'session'};

labs = fcat.strjoin( combs(labels, titles_are), ' | ' );
labs = strrep( labs, '_', ' ' );
title( labs );

if ( params.do_save )
  shared_utils.plot.fullscreen( f );
  save_p = get_plot_p( params );
  dsp3.req_savefig( f, save_p, labels, titles_are );
end

end

function plot_p = get_plot_p(params)

plot_p = fullfile( bfw.dataroot(params.config), 'plots', 'check_fixations' ...
  , dsp3.datedir );

end

function rects = normalize_rects(rects, min_x, max_x, min_y, max_y)

roi_names = keys( rects );
for i = 1:numel(roi_names)
  roi_name = roi_names{i};
  
  rect = bfw.norm_rect( rects(roi_name), min_x, max_x, min_y, max_y );
  % flip y
  rect([2, 4]) = 1 - rect([2, 4]);
  
  rects(roi_name) = rect;
end

end