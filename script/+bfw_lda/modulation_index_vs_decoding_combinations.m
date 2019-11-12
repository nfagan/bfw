function modulation_index_vs_decoding_combinations(rc, rc_mask, gc, gc_mask, varargin)

defaults = struct();
defaults.a_is = 'reward';
defaults.b_is = 'gaze';
defaults.do_save = true;
defaults.kinds = 'all';
defaults.abs_mod_index_combinations = false;
defaults.additional_each = {};
defaults.base_subdir = '';
defaults.plot = true;
defaults.permutation_test = false;
defaults.use_multi_regression = false;

params = bfw.parsestruct( defaults, varargin );

is_abs_mod_index = params.abs_mod_index_combinations;
condition_combs = dsp3.numel_combvec( is_abs_mod_index );

for i = 1:size(condition_combs, 2)
  comb = condition_combs(:, i);
  
  abs_modulation_index = is_abs_mod_index(comb(1));
  base_subdir = params.base_subdir;

  base_subdir = sprintf( '%s%s', base_subdir, gc.data_type );

  if ( abs_modulation_index )
    base_subdir = sprintf( '%s-abs', base_subdir );
  else
    base_subdir = sprintf( '%s-non-abs', base_subdir );
  end

  bfw_lda.modulation_index_vs_decoding_performance( rc.psth, rc.labels, rc_mask, gc.psth, gc.labels, gc_mask ...
    , 'do_save', params.do_save ...
    , 'rng_seed', 1 ...
    , 'abs_modulation_index', abs_modulation_index ...
    , 'base_subdir', base_subdir ...
    , 'kinds', params.kinds ...
    , 'a_is', params.a_is ...
    , 'b_is', params.b_is ...
    , 'a_type', rc.data_type ...
    , 'b_type', gc.data_type ...
    , 'additional_each', params.additional_each ...
    , 'plot', params.plot ...
    , 'permutation_test', params.permutation_test ...
    , 'use_multi_regression', params.use_multi_regression ...
  );
end

end