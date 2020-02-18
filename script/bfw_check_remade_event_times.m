bounds_file_subdir = 'raw_events_remade_021820_bounds_file_method';
roi_file_subdir = 'raw_events_remade_021820_roi_file_method';
old_method_subdir = 'archive_021820';

inputs = struct();

bounds_file_event_outs = bfw_gather_events( 'event_subdir', bounds_file_subdir, inputs );
roi_file_event_outs = bfw_gather_events( 'event_subdir', roi_file_subdir, inputs );
old_method_event_outs = bfw_gather_events( 'event_subdir', old_method_subdir, inputs );

%%

stim_event_outs = bfw_gather_events( 'config', bfw_st.default_config() );

%%

use_event_file = stim_event_outs;

roi_labels = use_event_file.labels';
mask = fcat.mask( roi_labels ...
  , @find, 'm1' ...
  , @find, {'eyes_nf', 'face'} ...
);

check_I = findall( roi_labels, {'unified_filename'}, mask );
start_indices = bfw.event_column( use_event_file, 'start_index' );
stop_indices = bfw.event_column( use_event_file, 'stop_index' );

num_use = numel( check_I );

for i = 1:num_use
%   assert( numel(unique(start_indices(check_I{i}))) == numel(check_I{i}) );
  
  keep = bfw_exclusive_events( start_indices, stop_indices, roi_labels ...
    , {{'eyes_nf', 'face'}}, check_I(i) );
  assert( numel(intersect(keep, check_I{i})) == numel(check_I{i}) );
end

%%

bounds_events = bounds_file_event_outs.events;
bounds_labels = bounds_file_event_outs.labels';
addsetcat( bounds_labels, 'event_method', 'bounds_file' );

roi_events = roi_file_event_outs.events;
roi_labels = roi_file_event_outs.labels';
addsetcat( roi_labels, 'event_method', 'roi_file' );

old_events = old_method_event_outs.events;
old_labels = old_method_event_outs.labels';
addsetcat( old_labels, 'event_method', 'old_method' );

event_key = bounds_file_event_outs.event_key;

events = [ bounds_events; roi_events; old_events ];
labels = [ bounds_labels'; roi_labels; old_labels ];

bfw.add_monk_labels( labels );

%%

check_I = findall( labels, {'unified_filename', 'event_method', 'looks_by'} );
start_indices = events(:, event_key('start_index'));
stop_indices = events(:, event_key('stop_index'));
num_use = numel( check_I );

for i = 1:num_use  
  keep = bfw_exclusive_events( start_indices, stop_indices, labels, {{'eyes_nf', 'face'}}, check_I(i) );
  check_I{i} = intersect( check_I{i}, keep );
end

exclusive_mask = vertcat( check_I{:} );

%%

durations = events(:, event_key('duration'));

thresholds = [0.025, 0.05, 0.075, 0.1];
thresh_labels = arrayfun( @(x) sprintf('threshold_%s', num2str(x)), thresholds, 'un', 0 );

[prop_labels, each_I] = keepeach( labels' ...
  , {'unified_filename', 'roi', 'looks_by', 'event_method'} );

below_thresh_labels = fcat();
prop_below_thresh = [];

for i = 1:numel(each_I)
  ps = nan( size(thresholds) );
  
  for j = 1:numel(thresholds)
    ps(j) = pnz( durations(each_I{i}) < thresholds(j) );
  end
  
  prop_below_thresh = [ prop_below_thresh; ps(:) ];
  
  tmp_labels = append1( fcat(), prop_labels, i, numel(thresholds) );
  addsetcat( tmp_labels, 'threshold', thresh_labels );
  append( below_thresh_labels, tmp_labels );
end

assert_ispair( prop_below_thresh, below_thresh_labels );

%%

pl = plotlabeled.make_common();
pl.y_lims = [0, 1];

fcats = { 'event_method' };
xcats = { 'looks_by' };
gcats = { 'threshold' };
pcats = { 'roi', 'event_method' };

mask = fcat.mask( below_thresh_labels ...
  , @find, {'roi_file', 'old_method'} ...
  , @find, combs(below_thresh_labels, 'roi', find(below_thresh_labels, 'roi_file')) ...
);

fig_I = findall_or_one( below_thresh_labels, fcats, mask );

for i = 1:numel(fig_I)
  figure(i);  
  tmp_data = prop_below_thresh(fig_I{i});
  tmp_labels = prune( below_thresh_labels(fig_I{i}) );
  
  axs = pl.bar( tmp_data, tmp_labels, xcats, gcats, pcats );
end

%%

% mask = find( durations >= 0.07 );
mask = exclusive_mask;
% mask = rowmask( labels );

[count_labels, each_I] = keepeach( labels' ...
  , {'unified_filename', 'roi', 'looks_by', 'event_method'}, mask );
counts = cellfun( @numel, each_I );

pl = plotlabeled.make_common();
pl.summary_func = @nanmedian;
pl.y_lims = [0, 100];

fcats = { };
xcats = { 'looks_by' };
gcats = { 'roi' };
pcats = { 'event_method' };

mask = fcat.mask( count_labels ...
  , @find, {'roi_file', 'old_method'} ...
  , @find, {'eyes_nf', 'face'} ...
);

fig_I = findall_or_one( count_labels, fcats, mask );

for i = 1:numel(fig_I)
  figure(i);  
  tmp_data = counts(fig_I{i});
  tmp_labels = prune( count_labels(fig_I{i}) );
  
  axs = pl.bar( tmp_data, tmp_labels, xcats, gcats, pcats );
end