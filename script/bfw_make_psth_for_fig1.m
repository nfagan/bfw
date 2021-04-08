function out = bfw_make_psth_for_fig1(varargin)

out = bfw_lda.generate_reward_and_gaze_spikes( ...
    'non_eye_face_method', false ...
  , 'spike_dir', 'cc_spikes' ...
  , 'events_subdir', 'raw_events_remade' ...
  , 'include_reward', false ...
  , 'include_rng', false ...
  , 'gaze_rois', make_rois() ...
  , 'do_save', false ...
  , 'include_rasters', true ...
  , varargin{:} ... 
);  

end

function rois = make_rois()

rois = { 'eyes_nf', 'face', 'right_nonsocial_object' ...
  , 'right_nonsocial_object_eyes_nf_matched' };

end