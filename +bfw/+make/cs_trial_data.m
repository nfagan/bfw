function trials_file = cs_trial_data(files)

bfw.validatefiles( files, 'cs_unified/m1' );

unified_file = shared_utils.general.get( files, 'cs_unified/m1' );

trial_data = unified_file.data.DATA;

reward_levels = get_reward_levels( trial_data );

trials_file = struct();
trials_file.unified_filename = bfw.try_get_unified_filename( unified_file );
trials_file.cs_unified_filename = unified_file.cs_unified_filename;
trials_file.reward_levels = reward_levels;

end

function reward_levels = get_reward_levels(trial_data)

if ( ~isfield(trial_data, 'n_rewards') )
  reward_levels = nan( numel(trial_data), 1 );
else
  reward_levels = reshape( [trial_data.n_rewards], [], 1 );
end

end