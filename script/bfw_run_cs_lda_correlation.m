function bfw_run_cs_lda_correlation(sens_perf, sens_p, sens_labels, lda_perf, lda_p, lda_labels, varargin)

defaults = struct();
defaults.absolute_sensitivity = false;
defaults.significant_sensitivity = false;
defaults.base_subdir = 'default';
defaults.do_save = false;

params = bfw.parsestruct( defaults, varargin );

if ( params.absolute_sentivity )
  sens_perf = abs( sens_perf );
  base_subdir = 'absolute_sens';
end

if ( params.significant_sensivity )
  sens_perf = indexpair( sens_perf, sens_labels, find(sens_p < 0.05) );
  base_subdir = sprintf( '%s_sig_reward', base_subdir );
end

% Additionally remove invalid units
sens_perf = indexpair( sens_perf, sens_labels, findnone(sens_labels, 'unit_uuid__NaN') );
lda_perf = indexpair( lda_perf, lda_labels, findnone(lda_labels, 'unit_uuid__NaN') );

[sens_perf, lda_perf, corr_labels] = ...
  bfw_make_reward_sensitivity_lda_distributions( sens_perf, sens_labels', lda_perf, lda_labels' );

bfw_correlate_cs_reward_sensitivity_to_gaze_lda( sens_perf, lda_perf, corr_labels ...
  , 'do_save', params.do_save ...
  , 'base_subdir', base_subdir ...
  , 'mask', findnone(corr_labels, 'shuffled') ...
); 

end