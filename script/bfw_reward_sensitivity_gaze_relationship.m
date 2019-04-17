function bfw_reward_sensitivity_gaze_relationship(sens_perf, sens_p, sens_labels, lda_outs, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
params = bfw.parsestruct( defaults, varargin );

mult_is_minus_null = [ true, false ];
mult_is_absolute_sensitivity = [ true, false ];
mult_is_significant_sensitivity = [ true, false ];
mult_is_significant_lda = [ true, false ];
mult_is_absolute_lda = [ true, false ];

C = dsp3.numel_combvec( mult_is_minus_null, mult_is_absolute_sensitivity ...
  , mult_is_significant_sensitivity, mult_is_significant_lda, mult_is_absolute_lda );

for i = 1:size(C, 2)
  shared_utils.general.progress( i, size(C, 2) );
  
  indices = C(:, i);
  
  is_minus_null = mult_is_minus_null(indices(1));
  is_absolute_sensitivity = mult_is_minus_null(indices(2));
  is_significant_sensitivity = mult_is_minus_null(indices(3));
  is_significant_lda = mult_is_minus_null(indices(4));
  is_absolute_lda = mult_is_absolute_lda(indices(5));
  
  if ( is_absolute_lda && ~is_minus_null )
    % Skip if using raw lda percent -- it's an absolute value already.
    continue;
  end

  [lda_perf, lda_p, lda_labels] = check_subtract_null( lda_outs, is_minus_null );
  base_subdir = get_base_subdir( params.base_subdir, is_minus_null );

  bfw_run_cs_lda_correlation( sens_perf, sens_p, sens_labels', lda_perf, lda_p, lda_labels' ...
    , 'significant_reward', is_significant_sensitivity ...
    , 'significant_gaze', is_significant_lda ...
    , 'absolute_gaze', is_absolute_lda ...
    , 'absolute_reward', is_absolute_sensitivity ...
    , 'do_save', params.do_save ...
    , 'base_subdir', base_subdir ...
  );
end

end

function base_subdir = get_base_subdir(base_subdir, is_minus_null)

if ( is_minus_null )
  base_subdir = sprintf( '%slda_minus_null', base_subdir );
else
  base_subdir = sprintf( '%slda_real_percent', base_subdir );
end

end

function [lda_perf, lda_p, lda_labels] = check_subtract_null(lda_out, is_minus_null)

lda_perf = lda_out.performance(:, 1);
lda_p = lda_out.performance(:, 3);
lda_labels = lda_out.labels';

if ( is_minus_null )
  func = @find;
else
  func = @findnone;
end

% For `is_minus_null == true`, this finds rows that are real-null.
% Otherwise, this finds rows that are *not* real-null.
shuff_ind = func( lda_labels, 'real-null' );

keep( lda_labels, shuff_ind );
lda_perf = lda_perf(shuff_ind);
lda_p = lda_p(shuff_ind);

end