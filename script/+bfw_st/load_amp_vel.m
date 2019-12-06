function amp_vel_outs = load_amp_vel(varargin)

defaults = bfw.get_common_make_defaults();
defaults.config = bfw.set_dataroot( bfw_st.make_data_root(defaults.config) );

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
  
amp_vel_outs = bfw_stim_amp_vs_vel( ...
    'look_ahead', 5 ...
  , 'files_containing', get_select_files(conf) ...
  , 'fixations_subdir', 'raw_eye_mmv_fixations' ...
  , 'samples_subdir', 'aligned_raw_samples' ...
  , 'minimum_fix_length', 10 ...
  , 'minimum_saccade_length', 10 ...
  , 'config', conf ...
);

end

function select_files = get_select_files(conf)

session_types = bfw.get_sessions_by_stim_type( conf, 'cache', true );

eyes_sessions = session_types.m1_exclusive_sessions;
face_sessions = session_types.m1_radius_sessions;

select_files = csunion( eyes_sessions, face_sessions );

end