function outs = bfw_spatially_binned_events(varargin)

defaults = bfw.get_common_make_defaults();
defaults.intermediate_subdir = 'aligned_raw_samples';
defaults.get_rois_func = @default_get_rois;
defaults.filter_rois_func = @default_filter_rois;
defaults.bin_size = 50;
defaults.num_bins = 100;
defaults.select_rois = {'eyes_nf', 'left_nonsocial_object'};

params = bfw.parsestruct( defaults, varargin );

sample_inputs = { 'position', 'raw_eye_mmv_fixations', 'time' };
remaining_inputs = { 'meta', 'rois' };

sample_inputs = shared_utils.io.fullfiles( params.intermediate_subdir, sample_inputs );
inputs = union( remaining_inputs, sample_inputs );

[params, runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();

results = runner.run( @main, params );
outputs = shared_utils.pipeline.extract_outputs_from_results( results );
outs = shared_utils.struct.soa( outputs );

end

function out = main(files, params)

fix_file = shared_utils.general.get( files, 'raw_eye_mmv_fixations' );
pos_file = shared_utils.general.get( files, 'position' );
roi_file = shared_utils.general.get( files, 'rois' );
meta_file = shared_utils.general.get( files, 'meta' );
t_file = shared_utils.general.get( files, 'time' );

position = pos_file.m1;
is_fix = fix_file.m1;

[fix_starts, fix_durs] = shared_utils.logical.find_islands( is_fix );
fix_positions = get_fixation_positions( position, fix_starts, fix_durs );

[rois, roi_labels] = feval( params.get_rois_func, roi_file );
[rois, roi_labels] = feval( params.filter_rois_func, rois, roi_labels, params.select_rois );

edges = ((0:params.num_bins+1) - params.num_bins/2) * params.bin_size;
% [x, y] = meshgrid( edges, edges );
x = edges;
y = edges;

% Rows are y, cols x
events = cell( numel(rois), numel(y)-1, numel(x)-1 );
relative_rois = nan( numel(rois), 4 );

for i = 1:numel(rois)
  roi = rois{i};
  roi_center = [ mean(roi([1, 3])), mean(roi([2, 4])) ];
  x_edges = x + roi_center(1);
  y_edges = y + roi_center(2);
  
  relative_roi = roi;
  relative_roi([1, 3]) = relative_roi([1, 3]) - roi_center(1);
  relative_roi([2, 4]) = relative_roi([2, 4]) - roi_center(2);
  relative_rois(i, :) = relative_roi;
  
  for j = 1:size(fix_positions, 2)
    x_ind = find( histc(fix_positions(1, j), x_edges), 1 );
    y_ind = find( histc(fix_positions(2, j), y_edges), 1 );
    
    has_x = ~isempty( x_ind ) && x_ind ~= numel( x_edges );
    has_y = ~isempty( y_ind ) && y_ind ~= numel( y_edges );
    
    if ( has_x && has_y )
      fix_start_t = t_file.t(fix_starts(j));
      fix_stop_t = t_file.t(fix_starts(j) + fix_durs(j)-1);
      
      if ( ~isnan(fix_start_t) && ~isnan(fix_stop_t) )
        events{i, y_ind, x_ind}(end+1, :) = [ fix_start_t, fix_stop_t ];
      end
    end
  end
end

labels = make_labels( meta_file, roi_labels );

out = struct();
out.events = events;
out.labels = labels;
out.x_edges = repmat( columnize(x(1:end-1))', rows(events), 1 );
out.y_edges = repmat( columnize(y(1:end-1))', rows(events), 1 );
out.relative_rois = relative_rois;

end

function labels = make_labels(meta_file, roi_labels)

labels = bfw.struct2fcat( meta_file );
roi_labels = fcat.from( roi_labels(:), 'roi' );

repmat( labels, rows(roi_labels) );
join( labels, roi_labels );

end

function fix_positions = get_fixation_positions(position, fix_starts, fix_durs)

fix_ends = fix_starts + fix_durs - 1;
fix_positions = arrayfun( @(x, y) nanmean(position(:, x:y), 2), fix_starts, fix_ends, 'un', 0 );
fix_positions = horzcat( fix_positions{:} );

end

function [rois, roi_labels] = default_filter_rois(rois, roi_labels, select_rois)

keep_rois = ismember( roi_labels, select_rois );
rois = rois(keep_rois);
roi_labels = roi_labels(keep_rois);

end

function [rects, roi_labels] = default_get_rois(roi_file)

rects = roi_file.m1.rects;
roi_labels = keys( rects );
rects = cellfun( @(x) rects(x), roi_labels, 'un', 0 );

end