% conf = bfw.set_dataroot( '~/Desktop/bfw' );

[gaze_counts, rwd_counts] = bfw_lda.load_gaze_reward_spikes( conf );

[~, gaze_ind] = bfw.make_whole_face_roi( gaze_counts.labels );

gaze_counts.events = gaze_counts.events(gaze_ind, :);
gaze_counts.spikes = gaze_counts.spikes(gaze_ind, :);

%%

conf = bfw.set_dataroot( '~/Desktop/bfw' );
gaze_counts = shared_utils.io.fload( fullfile(bfw.dataroot(conf) ...
  , 'analyses/spike_lda/joint_gaze_spikes/whole_face/joint_gaze_counts.mat') );

%%  gaze decoding

include_reward = false;
use_permutation_test = true;
gaze_decoding_type = 'roi';
specificity_type = 'per_region';

switch ( gaze_decoding_type )
  case 'roi'
    roi_pairs = { ...
        {'eyes_nf', 'nonsocial_object'} ...
      , {'eyes_nf', 'face'} ...
      , {'whole_face', 'nonsocial_object'} ...
    };
  
%     roi_pairs = { ...
%         {'eyes_nf', 'nonsocial_object'} ...
%     };
  
    gaze_condition_cat = 'roi';
    initiators = { {'m1', 'mutual'} };

  case 'joint_event_type'
    roi_pairs = { ...
      {'joint', 'no-joint'} ...
    };
  
    gaze_condition_cat = 'joint_event_type';
    initiators = { 'm1', 'm2' };
    
  otherwise
    error( 'Unrecognized gaze decoding type "%s".', gaze_decoding_type );
end

switch ( specificity_type )
  case 'per_unit'
    eaches = { {'region', 'session', 'unit_uuid'} };
    
  case 'per_session'
    eaches = { {'region'}, {'region', 'session'} };
    
  case 'per_run'
    eaches = { {'region', 'unified_filename'} };
    
  case 'per_region'
    eaches = { {'region'} };
    
  otherwise
    error( 'Unrecognized specificity type "%s".', specificity_type );
end

cs = dsp3.numel_combvec( roi_pairs, eaches, initiators );
nc = size( cs, 2 );

gaze_time_series = -0.5:0.05:0.5;
gaze_time_window = [-0.1, 0.1];

% gaze_time_series = 0;
% gaze_t_win = [0, 0.3];

store_over_time = cell( numel(gaze_time_series), 1 );

for idx = 1:numel(gaze_time_series)
  
fprintf( '\n %d of %d', idx, numel(gaze_time_series) );

all_perf = struct();
gaze_t_win = gaze_time_series(idx) + gaze_time_window;

for i = 1:nc
  
fprintf( '\n\t %d of %d', i, nc );
  
c = cs(:, i);
roi_pair = roi_pairs{c(1)};
each = eaches{c(2)};
initiator = initiators{c(3)};

roi_pair_str = strjoin( roi_pair, ' v. ' );
each_str = sprintf( 'each-%s', strjoin(each, '-') );

base_gaze_mask_func = @(l, m) fcat.mask(l, m ...
  , @find, roi_pair ...
  , @find, initiator ...
);

% Exclude samples associated with nonsocial object preceding the actual
% introduction of the object.
find_ns_obj = @(l) find(l, 'nonsocial_object');
gaze_mask_func = @(l, m) setdiff(...
  base_gaze_mask_func(l, m) ...
  , bfw.find_sessions_before_nonsocial_object_was_added(l, find_ns_obj(l)) ...
);

rwd_mask_func = @(l, m) fcat.mask(l, m ...
  , @find, {'cs_target_acquire'} ...
  , @find, {'reward-1', 'reward-3'} ...
);

decode_outs = bfw_lda.revisit_population_decoding( gaze_counts, rwd_counts ...
  , 'permutation_test', use_permutation_test ...
  , 'gaze_mask_func', gaze_mask_func ...
  , 'rwd_mask_func', rwd_mask_func ...
  , 'each', each ...
  , 'iters', 100 ...
  , 'include_reward', include_reward ...
  , 'resample_to_larger_n', true ...
  , 'model_type', 'lda' ...
  , 'gaze_condition', gaze_condition_cat ...
  , 'gaze_t_win', gaze_t_win ...
);

lab_fs = { 'labels', 'p_labels' };
for j = 1:numel(lab_fs)
  maybe_addsetcat( decode_outs.(lab_fs{j}), 'roi-pairs', roi_pair_str );
  maybe_addsetcat( decode_outs.(lab_fs{j}), 'each', each_str );
end

if ( i == 1 )
  all_perf = decode_outs;
else
  fs = fieldnames( decode_outs );
  for j = 1:numel(fs)
    all_perf.(fs{j}) = [all_perf.(fs{j}); decode_outs.(fs{j})];
  end
end

end

store_over_time{idx} = all_perf;

end

%%

perf = cat_expanded( 2, cellfun(@(x) x.performance, store_over_time, 'un', 0) );
perf_labels = store_over_time{1}.labels;

ps = cat_expanded( 2, cellfun(@(x) x.ps(:, 1), store_over_time, 'un', 0) );
p_labels = store_over_time{1}.p_labels;

for i = 2:numel(store_over_time)
  cats = setdiff( getcats(perf_labels), 'comb-uuid' );
  c = categorical( perf_labels, cats );
  s = categorical( store_over_time{i}.labels, cats );
  assert( isequal(c, s) );
end

bfw_lda.plot_decoding_over_time_performance( perf, perf_labels', gaze_time_series, ps, p_labels' ...
  , 'cats', {{}, {'region'}, {'roi-pairs'}} ...
  , 'p_match', {'region', 'roi-pairs'} ...
  , 'config', conf ...
  , 'do_save', true ...
); 

%%
% base_subdir = 'per_region_bagged_trees';
% base_subdir = 'per_unit';
base_subdir = 'per_region';

% date_dir = '052020';
date_dir = '080520';

save_dir = fullfile( bfw.dataroot(conf), 'analyses', 'cs_sens_vs_lda' ...
  , date_dir, base_subdir );

%%

shared_utils.io.require_dir( save_dir );
save( fullfile(save_dir, 'perf.mat'), 'all_perf' );

%%

all_perf = shared_utils.io.fload( fullfile(save_dir, 'perf.mat') );

%%  scatter gaze v. duration modulation index

base_mask = fcat.mask( all_perf.labels ...
  , @find, {'real'} ...
);

each_I = findall( all_perf.labels, {'roi-pairs', 'each'}, base_mask );

event_mask_func = @(l, m) fcat.mask(l, m ...
  , @find, {'m1'} ...
);

% lda_each = {'region', 'session'};
lda_each = {'region', 'unit_uuid', 'session'};
behav_metrics = { 'nfix', 'duration', 'total_duration' };

cs = dsp3.numel_combvec( each_I, behav_metrics );

for i = 1:size(cs, 2)
  c = cs(:, i);
  each_ind = each_I{c(1)};
  behav_metric = behav_metrics{c(2)};
  
  perf_mask_func = @(l, m) intersect(m, each_ind);
  
  event_info = struct( ...
    'events', gaze_counts.events ...
    , 'event_key', gaze_counts.event_key ...
    , 'labels', gaze_counts.labels' ...
  );

  base_subdir = behav_metric;

  bfw_lda.scatter_gaze_perf_vs_modulation_index( ...
    all_perf.performance, all_perf.labels', event_info ...
    , 'mask_func', perf_mask_func ...
    , 'event_mask_func', event_mask_func ...
    , 'do_save', true ...
    , 'config', conf ...
    , 'lda_each', lda_each ...
    , 'behav_metric', behav_metric ...
    , 'base_subdir', base_subdir ...
  );
end

%%  scatter gaze v. reward perf

base_mask = fcat.mask( all_perf.labels ...
  , @find, {'each-region-session', 'real'} ...
);

each_I = findall( all_perf.labels, 'roi-pairs', base_mask );

for i = 1:numel(each_I)
  perf_mask_func = @(l, m) intersect(m, each_I{i});

  bfw_lda.scatter_reward_vs_gaze_session_perf( all_perf.performance, all_perf.labels' ...
    , 'mask_func', perf_mask_func ...
    , 'do_save', true ...
    , 'config', conf ...
  );
end

%%  plot perf

use_gaze = true;
do_save = true;

perf_mask_func = @(l, m) fcat.mask( l, m ...
  , @find, {'each-region'} ...
);

if ( use_gaze )  
  perf = all_perf.performance(:, 1);
  base_subdir = 'gaze-performance';
else
  perf_mask_func = @(l, m) intersect(perf_mask_func(l, m) ...
    , find(l, ref(combs(l, 'roi-pairs', m), '()', 1)) ...
  );

  perf = all_perf.performance(:, 2);
  base_subdir = 'rwd-performance';
end

bfw_lda.plot_accuracy( perf, all_perf.labels' ...
  , 'mask_func', perf_mask_func ...
  , 'do_save', do_save ...
  , 'config', conf ...
  , 'base_subdir', base_subdir ...
);

%%  plot sig

use_gaze = true;
do_save = false;

perf_mask_func = @(l, m) fcat.mask( l, m ...
  , @find, {'each-region-session'} ...
);

if ( use_gaze )  
  ps = all_perf.ps(:, 1);
  base_subdir = 'gaze-performance';
else
  perf_mask_func = @(l, m) intersect(perf_mask_func(l, m) ...
    , find(l, ref(combs(l, 'roi-pairs', m), '()', 1)) ...
  );

  ps = all_perf.ps(:, 2);
  base_subdir = 'rwd-performance';
end

bfw_lda.plot_proportion_sig_sessions( ps, all_perf.p_labels' ...
  , 'mask_func', perf_mask_func ...
  , 'do_save', do_save ...
  , 'config', conf ...
  , 'base_subdir', base_subdir ...
);


