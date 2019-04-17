function bfw_run_cs_lda_correlation(sens_perf, sens_p, sens_labels, lda_perf, lda_p, lda_labels, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.alpha = 0.05;
defaults.absolute_reward = false;
defaults.absolute_gaze = false;
defaults.significant_reward = false;
defaults.significant_gaze = false;
defaults.base_subdir = '';
defaults.do_save = false;

assert_ispair( sens_p, sens_labels );
assert_ispair( lda_p, lda_labels );

params = bfw.parsestruct( defaults, varargin );

[sens_perf, lda_perf, base_subdir] = ...
  handle_combinations( sens_perf, sens_p, sens_labels, lda_perf, lda_p, lda_labels, params );

% Additionally remove invalid units.
sens_perf = remove_invalid_units( sens_perf, sens_labels );
lda_perf = remove_invalid_units( lda_perf, lda_labels );

[sens_perf, lda_perf, corr_labels] = ...
  bfw_make_reward_sensitivity_lda_distributions( sens_perf, sens_labels', lda_perf, lda_labels' );

bfw_correlate_cs_reward_sensitivity_to_gaze_lda( sens_perf, lda_perf, corr_labels ...
  , 'do_save', params.do_save ...
  , 'base_subdir', base_subdir ...
  , 'mask', findnone(corr_labels, 'shuffled') ...
  , 'config', params.config ...
); 

end

function [perf, labels] = remove_invalid_units(perf, labels)

% From the rows of `perf` that aren't nan, find rows of `labels` that have
% a valid unit uuuid.
nan_ind = find( ~isnan(perf) );
valid_ind = findnone( labels, 'unit_uuid__NaN', nan_ind );

[perf, labels] = indexpair( perf, labels, valid_ind );

end

function [sens_perf, lda_perf, base_subdir] = ...
  handle_combinations(sens_perf, sens_p, sens_labels, lda_perf, lda_p, lda_labels, params)

base_subdir = params.base_subdir;

if ( params.absolute_reward )
  sens_perf = abs( sens_perf );
  base_subdir = sprintf( '%s_absolute_sens', base_subdir );
end

if ( params.significant_reward )
  sens_perf = indexpair( sens_perf, sens_labels, find(sens_p < params.alpha) );
  base_subdir = sprintf( '%s_sig_reward', base_subdir );
end

if ( params.significant_gaze )
  lda_perf = indexpair( lda_perf, lda_labels, find(lda_p < params.alpha) );  
  base_subdir = sprintf( '%s_sig_gaze', base_subdir );
end

if ( params.absolute_gaze )
  lda_perf = abs( lda_perf );
  base_subdir = sprintf( '%s_absolute_gaze', base_subdir );
end

end