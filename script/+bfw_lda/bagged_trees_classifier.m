%{
@T begin
import mt.base

record Labels
end

record SpikeInfo
  spikes: double
  labels: Labels
  mask: double
  target_category: char
end
record ClassifyParams
  seed: double
end
record Params
  seed: double
  gaze_t_win: double
  permutation_test: logical
  permutation_test_iters: double
  mask_func: [double] = (Labels, double)
  spike_func: [double] = (double)
  alpha: double
  reward_time_windows: {list<double>}
  spike_criterion_func: [uint64] = (double, Labels, double | uint64)
end

end
%}
function outs = bagged_trees_classifier(gaze_counts, rwd_counts, varargin)

[~, reward_time_windows] = bfw_lda.reward_time_windows();

% @T constructor
defaults = struct( ...
    'seed', 0 ...
  , 'gaze_t_win', [0, 0.3] ...
  , 'permutation_test', false ...
  , 'permutation_test_iters', 1e2 ...
  , 'mask_func', @bfw.default_mask_func ...
  , 'spike_func', @(x) nanmean(x, 2) ...
  , 'alpha', 0.05 ...
  , 'reward_time_windows', {reward_time_windows} ...
  , 'spike_criterion_func', @(s, l, m) m ...
);

params = get_params( defaults, varargin );

%%

shared_ids = bfw_lda.shared_unit_ids( gaze_counts.labels, rwd_counts.labels );

%%

num_units = size( shared_ids, 2 );

% @T constructor
classify_params = struct( ...
  'seed', params.seed ...
);

gaze_min_t = params.gaze_t_win(1);
gaze_max_t = params.gaze_t_win(2);

gaze_t_ind = gaze_counts.t >= gaze_min_t & gaze_counts.t <= gaze_max_t;
select_gaze_spikes = select_spikes( gaze_counts.spikes, gaze_t_ind, params.spike_func );

% nanmean( gaze_counts.spikes(:, gaze_t_ind), 2 );

[rwd_t_windows, rwd_event_names] = bfw_lda.reward_time_windows();
keep_ind = ismember( rwd_event_names, params.reward_time_windows );

rwd_t_windows = rwd_t_windows(keep_ind);
rwd_event_names = rwd_event_names(keep_ind);
rwd_base_mask = get_rwd_base_mask( rwd_counts.labels, params.mask_func, rwd_event_names );

gaze_base_mask = get_gaze_base_mask( gaze_counts.labels, params.mask_func );

rwd_I = cellfun( @(x) find(rwd_counts.labels, x, rwd_base_mask), rwd_event_names, 'un', 0 );

accuracies = [];
accuracy_labels = fcat();

for idx = 1:numel(rwd_I)
  shared_utils.general.progress( idx, numel(rwd_I) );
  
  rwd_each_ind = rwd_I{idx};
  rwd_t_win = rwd_t_windows{idx};
  rwd_t_ind = rwd_counts.t >= rwd_t_win(1) & rwd_counts.t <= rwd_t_win(2);
  select_rwd_spikes = select_spikes( rwd_counts.psth, rwd_t_ind, params.spike_func );
  
  tmp_accuracies = cell( num_units, 1 );
  tmp_labels = cell( size(tmp_accuracies) );

  for i = 1:num_units
    shared_utils.general.progress( i, num_units );
    
    unit_selectors = shared_ids(:, i);
    gaze_ind = find( gaze_counts.labels, unit_selectors, gaze_base_mask );
    rwd_ind = find( rwd_counts.labels, unit_selectors, rwd_each_ind );
    
    gaze_ind = params.spike_criterion_func( select_gaze_spikes, gaze_counts.labels, gaze_ind );
    rwd_ind = params.spike_criterion_func( select_rwd_spikes, rwd_counts.labels, rwd_ind );
    
    if ( isempty(gaze_ind) || isempty(rwd_ind) )
      continue;
    end
    
    % @T constructor
    gaze_spike_info = struct( ...
        'spikes', select_gaze_spikes ...
      , 'labels', gaze_counts.labels ...
      , 'mask', gaze_ind ...
      , 'target_category', 'roi' ...
    );
  
    % @T constructor
    rwd_spike_info = struct( ...
        'spikes', select_rwd_spikes ...
      , 'labels', rwd_counts.labels ...
      , 'mask', rwd_ind ...
      , 'target_category', 'reward-level' ...
    );
  
    try
      gaze_accuracy = run_classification_from_info( gaze_spike_info, classify_params );
      rwd_accuracy = run_classification_from_info( rwd_spike_info, classify_params );

      tmp_result_labs = append1( fcat, gaze_counts.labels, gaze_ind );
      tmp_rwd_labs = append1( fcat, rwd_counts.labels, rwd_ind );
      join( tmp_result_labs, tmp_rwd_labs );
      addsetcat( tmp_result_labs, 'data-type', 'real' );

      tmp_accuracy = [gaze_accuracy, rwd_accuracy];

      if ( params.permutation_test )      
        [gaze_null, use_null_labels] = ...
          permutation_test( gaze_spike_info, tmp_result_labs', classify_params, params );
        [rwd_null, ~] = ...
          permutation_test( rwd_spike_info, tmp_result_labs', classify_params, params );

        gaze_sig_label = ...
          ternary( check_significance(gaze_null, gaze_accuracy, params.alpha) ...
            , 'gaze-sig-true', 'gaze-sig-false' );
        rwd_sig_label = ...
          ternary( check_significance(rwd_null, rwd_accuracy, params.alpha) ...
            , 'rwd-sig-true', 'rwd-sig-false' );

        addsetcat( use_null_labels, 'gaze-sig', gaze_sig_label );
        addsetcat( use_null_labels, 'rwd-sig', rwd_sig_label );

        null_accuracy = [ gaze_null, rwd_null ];
        tmp_accuracy = [ tmp_accuracy; null_accuracy ];

        addcat( tmp_result_labs, getcats(use_null_labels) );
        append( tmp_result_labs, use_null_labels );
      end

      tmp_labels{i} = tmp_result_labs;
      tmp_accuracies{i} = tmp_accuracy;
      
    catch err
      warning( err.message );
    end
  end
  
  non_empties = ~cellfun( @isempty, tmp_labels );
  
  append( accuracy_labels, vertcat(fcat, tmp_labels{non_empties}) );
  accuracies = [ accuracies; vertcat(tmp_accuracies{non_empties}) ];
end

outs = struct();
outs.accuracies = accuracies;
outs.accuracy_labels = accuracy_labels;
outs.params = params;

end

% @T :: [Params] = (Params, ?)
function params = get_params(defaults, varargin)
params = bfw.parsestruct( defaults, varargin );
end

% @T :: [logical] = (double, double, double)
function tf = check_significance(null_dist, real_val, alpha_thresh)
  
tf = pnz( null_dist > real_val ) < alpha_thresh;
  
end

% @T :: [double, Labels] = (SpikeInfo, Labels, ClassifyParams, Params)
function [accuracies, out_labels] = permutation_test(spike_info, dest_labels, classify_params, params)

spikes = spike_info.spikes;
labels = spike_info.labels;
mask = spike_info.mask;
target_category = spike_info.target_category;

accuracies = nan( params.permutation_test_iters, 1 );
out_labels = cell( size(accuracies) );

parfor i = 1:params.permutation_test_iters
  label_mask = mask(randperm(numel(mask)));
  
  accuracy = run_classification( spikes, labels, target_category, mask ...
    , label_mask, classify_params );
  
  cp_labels = copy( dest_labels );
  setcat( cp_labels, 'data-type', 'null' );
  
  out_labels{i} = cp_labels;
  accuracies(i) = accuracy;
end

out_labels = vertcat( fcat, out_labels{:} );

end

% @T :: [double] = (double, double, [double] = (double))
function s = select_spikes(spikes, time_ind, func)

s = func( spikes(:, time_ind) );

end

% @T :: [double] = (SpikeInfo, ClassifyParams)
function accuracy = run_classification_from_info(spike_info, classify_params)

accuracy = run_classification( spike_info.spikes, spike_info.labels ...
  , spike_info.target_category, spike_info.mask, spike_info.mask, classify_params );

end

% @T :: [double] = (double, Labels, char, double, double, ClassifyParams)
function accuracy = run_classification(spikes, labels, target_category ...
  , spike_mask, label_mask, classify_params)

if ( isempty(spike_mask) )
  accuracy = nan;
else
  [~, accuracy] = bfw_lda.bagged_trees_vector_spike_classifier( ...
    spikes, labels, target_category, spike_mask, classify_params ... 
    , 'label_mask', label_mask ...
  );
end

end

function gaze_base_mask = get_gaze_base_mask(labels, mask_func)

gaze_base_mask = fcat.mask( labels ...
  , @find, {'face', 'eyes_nf', 'nonsocial_object'} ...
  , @find, 'm1' ...
);

gaze_base_mask = mask_func( labels, gaze_base_mask );

end

function rwd_base_mask = get_rwd_base_mask(labels, mask_func, rwd_event_names)

rwd_base_mask = fcat.mask( labels ...
  , @find, rwd_event_names ...
  , @findnone, 'reward-NaN' ...
  , @find, 'no-error' ...
);

rwd_base_mask = mask_func( labels, rwd_base_mask );

end