function unit_info = load_sig_reward_level_unit_info(subdirs, varargin)

unit_info = shared_utils.io.fload( fullfile(bfw.dataroot(varargin{:}) ...
  , 'analyses', 'cs_reward', 'reward_level_modulation', subdirs{:} ...
  , 'cc_sig_unit_info.mat') );

end