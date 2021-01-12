% @T import mt.base
% event_subdir = '031720_70ms_non_binned';
event_subdir = '040320_70ms_non_binned_mouth';

events = bfw_gather_events( ...
  'event_subdir', event_subdir ...
);

%%

sorted_events = bfw.sort_events( events );
bfw.add_monk_labels( sorted_events.labels );
bfw.add_excl_monk_labels( sorted_events.labels );
bfw.add_monk_pair_labels( sorted_events.labels );

prune( sorted_events.labels );

%%

conf = bfw.set_dataroot( '~/Desktop/bfw' );

%%

sorted_events = shared_utils.io.fload( fullfile(bfw.dataroot(conf) ...
  , 'analyses/events/sorted_events.mat') );

[~, transform_ind] = bfw.make_whole_face_roi( sorted_events.labels );
sorted_events.events = sorted_events.events(transform_ind, :);
labs = sorted_events.labels';

%%

n_back_mask_func = @(l, m) fcat.mask(l, m ...
  , @findor, {'eyes_nf', 'mouth', 'face'} ...
);

back_of = { 'roi', 'looks_by' };
% @T constructor
common_inputs = struct( 'mask_func', n_back_mask_func, 'of', {back_of} );

[prevs, prev_ts] = bfw.n_back_event_labels( sorted_events, 'num_back', -1, common_inputs );
[nexts, next_ts] = bfw.n_back_event_labels( sorted_events, 'num_back', 1, common_inputs );

labs = sorted_events.labels';
bfw.add_n_back_labels( labs, prevs, back_of, 'prev_' );
bfw.add_n_back_labels( labs, nexts, back_of, 'next_' );

%%

back_thresh = 1;
back_within_thresh = @(l, m) intersect(m, find(abs(prev_ts) <= back_thresh));

%%

make_ratio = false;
nonsocial_obj_rois = {'right_nonsocial_object', 'right_nonsocial_object_eyes_nf_matched'};
collapse_event_type = true;

if ( make_ratio )
  possible_rois = {'eyes_nf', 'face', 'mouth' ...
  , 'right_nonsocial_object', 'whole_face', 'right_nonsocial_object_eyes_nf_matched'};
else
  possible_rois = {'eyes_nf', 'face', 'mouth' ...
    , 'right_nonsocial_object'};
end

base_mask_func = @(l, m) fcat.mask( l, m ...
  , @findor, possible_rois ...
  , @findnot, {'right_nonsocial_object', 'mutual', 'm2'} ...
);

if ( make_ratio )
  base_mask_func = @(l, m) base_mask_func(l, find(l, 'exclusive_event', m));
end

find_ns_objs = @(labels) findor(labels, nonsocial_obj_rois);

% Remove samples of the "nonsocial object roi" prior to the actual
% introduction of the object.
base_mask_func = @(l, m) setdiff(...
    base_mask_func(l, m) ...
  , bfw.find_sessions_before_nonsocial_object_was_added(l, find_ns_objs(l)) ...
);

require_n_back_within_thresh = false;

if ( require_n_back_within_thresh )
  mask_func = @(l, m) base_mask_func(l, back_within_thresh(l, m));
else
  mask_func = base_mask_func;
end

use_labs = labs';

if ( collapse_event_type )
  collapsecat( use_labs, 'event_type' );
end

has_mouth = ~isempty( find(use_labs, 'mouth') );
base_spec = { 'unified_filename', 'roi' };
% base_spec = { 'roi', 'session' };

if ( has_mouth )
  base_subdir = 'mouth';
else
  base_subdir = 'non-mouth';
end

if ( ismember({'unified_filename'}, base_spec) )
  base_subdir = sprintf( 'run-level-%s', base_subdir );
else
  base_subdir = sprintf( 'day-level-%s', base_subdir );
end

per_monks = false;
per_pairs = false;
per_excl = false;
% is_normalized_ratio = trufls;
is_normalized_ratio = true;
cs = dsp3.numel_combvec( per_monks, per_pairs, per_excl, is_normalized_ratio );

for i = 1:size(cs, 2)
  shared_utils.general.progress( i, size(cs, 2) );
  
  c = cs(:, i);
  per_m1_m2 = per_monks(c(1));
  per_m1_m2_pair = per_pairs(c(2));
  per_exlusive_monk_id = per_excl(c(3));
  normalized_ratio = is_normalized_ratio(c(4));

  use_base_subdir = base_subdir;
  if ( normalized_ratio )
    use_base_subdir = sprintf( '%s-norm-ratio', use_base_subdir );
  end

  bfw_plot_event_summary( sorted_events, use_labs ...
    , 'mask_func', mask_func ...
    , 'per_m1_m2', per_m1_m2 ...
    , 'per_m1_m2_pair', per_m1_m2_pair ...
    , 'per_exlusive_monk_id', per_exlusive_monk_id ...
    , 'do_save', true ...
    , 'config', conf ...
    , 'base_subdir', use_base_subdir ...
    , 'base_specificity', base_spec ...
    , 'normalized_ratio', normalized_ratio ...
    , 'x_order', {'eyes_nf', 'mouth', 'face'} ...
  );
end

%%

conf = bfw.set_dataroot( '~/Desktop/bfw/' );

sessions = combs( sorted_events.labels, 'session' );
first_runs = eachcell( @(x) sprintf('%s_position_1.mat', x), sessions );

% use_runs = {'01022019_position_1.mat'};
use_runs = first_runs;
use_rois = {'eyes_nf', 'face'};

find_some_runs = @(l, m) findor(l, use_runs, m);
find_some_rois = @(l, m) findor(l, use_rois, m);

mask_funcs = { find_some_runs, find_some_rois };
mask_func = bfw.make_apply_mask_funcs( mask_funcs );

bfw_plot_event_timeline( sorted_events.events, sorted_events.event_key ...
  , sorted_events.labels' ...
  , 'config', conf ...
  , 'mask_func', mask_func ...
  , 'color_func', @spring ...
  , 'each', {'looks_by', 'roi'} ...
  , 'panels', {'unified_filename', 'm1_m2'} ...
  , 'figures', {'unified_filename', 'm1_m2'} ...
  , 'x_lims', [] ...
  , 'do_save', true ...
  , 'y_lims', [-2, 5] ...
  , 'box_height', 1 ...
  , 'box_y_offset', 2 ...
);