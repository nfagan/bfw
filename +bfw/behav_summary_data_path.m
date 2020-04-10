function p = behav_summary_data_path(data_type, subdir, params)

p = fullfile( bfw.dataroot(params.config), 'plots' ...
  , data_type, dsp3.datedir, params.base_subdir, subdir );

end