% bfw_make_raw_stimulation_events( ...
%     'config', bfw_st.default_config() ...
%   , 'overwrite', false ...
%   , 'samples_subdir', 'aligned_binned_raw_samples' ...
%   , 'fixations_subdir', 'raw_eye_mmv_fixations' ...
% );

%%

bfw_make_raw_stimulation_events( ...
    'config', bfw_st.default_config() ...
  , 'overwrite', false ...
  , 'samples_subdir', 'aligned_raw_samples' ...
  , 'fixations_subdir', 'raw_eye_mmv_fixations' ...
  , 'use_bounds_file_for_rois', false ...
  , 'check_accept_mutual_event_func', @bfw.default_check_accept_mutual_event_func ...
  , 'duration', 70 ...
);