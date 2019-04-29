function population_decode_gaze_from_reward(gaze_counts, reward_counts, varargin)

defaults = bfw.get_common_make_defaults();
defaults.gaze_t_window = [ 0.1, 0.4];  % s
defaults.reward_t_window = [ 0.1, 0.4 ];  % s

params = bfw.parsestruct( defaults, varargin );

keep_reward = reward_criterion( reward_counts );
keep_gaze = gaze_criterion( gaze_counts, reward_counts, keep_reward );

collapsed_rwd = collapse_counts( reward_counts.psth, reward_counts.t, params.reward_t_window );
collapsed_gaze = collapse_counts( gaze_counts.spikes, gaze_counts.t, params.gaze_t_window );

[collapsed_rwd, rwd_labels] = indexpair( collapsed_rwd, reward_counts.labels', keep_reward );
[collapsed_gaze, gaze_labels] = indexpair( collapsed_gaze, gaze_counts.labels', keep_gaze );

bfw.unify_single_region_labels( gaze_labels );
bfw.unify_single_region_labels( rwd_labels );

prune( rwd_labels );
prune( gaze_labels );

end

function per_bin_and_condition()


end

function meets_criterion = gaze_criterion(gaze, reward, reward_mask)

reward_units = combs( reward.labels, 'unit_uuid', reward_mask );
meets_criterion = findor( gaze.labels, reward_units );

end

function meets_criterion = reward_criterion(reward)

meets_criterion = false( rows(reward.labels), 1 );

% Remove unit_uuid_NaN, error trials, and baseline.
base_mask = fcat.mask( reward.labels ...
  , @findnone, nan_unit_id() ...
  , @find, 'no-error' ...
  , @findnone, 'iti' ...
);

unit_I = findall( reward.labels, {'unit_uuid', 'session', 'region'}, base_mask );

% Require at least N trials of each 'reward-level'.
condition_combs = combs( reward.labels, 'reward-level' );
condition_threshold = 5;

for i = 1:numel(unit_I)
  for j = 1:size(condition_combs, 2)
    cond_ind = find( reward.labels, condition_combs(:, j), unit_I{i} );
    n_cond = numel( cond_ind );
    
    if ( n_cond >= condition_threshold )
      meets_criterion(cond_ind) = true;
    end
  end
end

% evt_names = combs( reward.labels, 'event-name' );
% baseline_evt = 'iti';
% 
% assert( ismember(baseline_evt, evt_names), 'Missing baseline event: "%s".', baseline_evt );
% 
% target_evts = setdiff( evt_names, baseline_evt );
% 
% for i = 1:numel(unit_I)
%   for j = 1:numel(target_evts)
%     targ_ind = find( reward.labels, target_evts{j}, unit_I{i} );
%     base_ind = find( reward.labels, baseline_evt, unit_I{i} );
%     
%     assert( numel(targ_ind) == numel(base_ind) );
%     
%     mean_targ = nanmean( reward.
%   end
% end

meets_criterion = find( meets_criterion );

end

function counts = collapse_counts(counts, t, t_window)

t_ind = t >= t_window(1) & t <= t_window(2);
counts = nansum( counts(:, t_ind), 2 );

end

function id = nan_unit_id()
id = 'unit_uuid__NaN';
end

