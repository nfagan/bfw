function labels_file = cs_labels(files)

bfw.validatefiles( files, {'cs_unified/m1', 'meta'} );

unified_file = shared_utils.general.get( files, 'cs_unified/m1' );
meta_file = shared_utils.general.get( files, 'meta' );

trial_data = unified_file.data.DATA;

reward_levels = get_reward_levels( trial_data );
error_types = get_error_types( trial_data );

labels = fcat.from( [reward_levels, error_types], {'reward-level', 'error-type'} );
meta_labels = get_meta_labels( unified_file, meta_file );

join( labels, meta_labels );

labels_file = struct();
labels_file.unified_filename = bfw.try_get_unified_filename( unified_file );
labels_file.cs_unified_filename = unified_file.cs_unified_filename;
labels_file.labels = labels;

end

function meta_labels = get_meta_labels(unified_file, meta_file)

meta_labels = bfw.struct2fcat( convert_meta_file_to_cs_meta_file(unified_file, meta_file) );

end

function meta_file = convert_meta_file_to_cs_meta_file(unified_file, meta_file)

% Update task type
meta_file.task_type = 'cs';

% Include cs_unified_filename in addition to unified_filename
meta_file.cs_unified_filename = unified_file.cs_unified_filename;

end

function error_types_str = get_error_types(trial_data)

error_types_str = cell( numel(trial_data), 1 );

for i = 1:numel(trial_data)
  errors = trial_data(i).errors;
  
  any_errors = any( structfun(@deal, errors) );
  
  if ( ~any_errors )
    error_types_str{i} = 'no-error';
  else
    if ( errors.broke_initial_fixation )
      error_types_str{i} = 'broke-initial-fixation';
      
    elseif ( errors.initial_fixation_not_acquired )
      error_types_str{i} = 'initial-fixation-not-acquired';
      
    elseif ( errors.broke_cs_fixation )
      error_types_str{i} = 'broke-cs-fixation';
      
    elseif ( errors.cs_fixation_not_acquired )
      error_types_str{i} = 'cs-fixation-not-acquired';
      
    else
      error_types_str{i} = '<unhandled-error-type>';
    end
  end
end

end

function reward_levels_str = get_reward_levels(trial_data)

if ( ~isfield(trial_data, 'n_rewards') )
  reward_levels = nan( numel(trial_data), 1 );
else
  reward_levels = reshape( [trial_data.n_rewards], [], 1 );
end

reward_levels_str = arrayfun( @(x) sprintf('reward-%d', x), reward_levels, 'un', 0 );

end