conf = bfw.set_dataroot( '~/Desktop/bfw' );

[gaze_counts, rwd_counts] = bfw_lda.load_gaze_reward_spikes( conf );

%%

roi_pairs = { ...
    {'eyes_nf', 'nonsocial_object'} ...
  , {'eyes_nf', 'face'} ...
  , {'face', 'nonsocial_object'} ...
};

eaches = { {'region'}, {'region', 'session'} };
cs = dsp3.numel_combvec( roi_pairs, eaches );
nc = size( cs, 2 );

all_perf = struct();

for i = 1:nc
  
shared_utils.general.progress( i, nc );
  
c = cs(:, i);
roi_pair = roi_pairs{c(1)};
each = eaches{c(2)};

roi_pair_str = strjoin( roi_pair, ' v. ' );
each_str = sprintf( 'each-%s', strjoin(each, '-') );

gaze_mask_func = @(l, m) fcat.mask(l, m ...
  , @find, roi_pair ...
  , @find, {'m1'} ...
);

rwd_mask_func = @(l, m) fcat.mask(l, m ...
  , @find, {'cs_target_acquire'} ...
);

decode_outs = bfw_lda.revisit_population_decoding( gaze_counts, rwd_counts ...
  , 'permutation_test', true ...
  , 'gaze_mask_func', gaze_mask_func ...
  , 'rwd_mask_func', rwd_mask_func ...
  , 'each', each ...
  , 'iters', 100 ...
);

lab_fs = { 'labels', 'p_labels' };
for j = 1:numel(lab_fs)
  maybe_addsetcat( decode_outs.(lab_fs{j}), 'roi-pairs', roi_pair_str );
  maybe_addsetcat( decode_outs.(lab_fs{j}), 'each', each_str );
end

if ( i == 1 )
  all_perf = decode_outs;
else
  fs = fieldnames( decode_outs );
  for j = 1:numel(fs)
    all_perf.(fs{j}) = [all_perf.(fs{j}); decode_outs.(fs{j})];
  end
end

end

%%  scatter gaze v. reward perf

base_mask = fcat.mask( all_perf.labels ...
  , @find, {'each-region-session', 'real'} ...
);

each_I = findall( all_perf.labels, 'roi-pairs', base_mask );

for i = 1:numel(each_I)
  perf_mask_func = @(l, m) intersect(m, each_I{i});

  bfw_lda.scatter_reward_vs_gaze_session_perf( all_perf.performance, all_perf.labels' ...
    , 'mask_func', perf_mask_func ...
    , 'do_save', true ...
    , 'config', conf ...
  );
end

%%  plot perf

use_gaze = true;

perf_mask_func = @(l, m) fcat.mask( l, m ...
  , @find, {'each-region'} ...
);

if ( use_gaze )  
  perf = all_perf.performance(:, 1);
  base_subdir = 'gaze-performance';
else
  perf_mask_func = @(l, m) intersect(perf_mask_func(l, m) ...
    , find(l, ref(combs(l, 'roi-pairs', m), '()', 1)) ...
  );

  perf = all_perf.performance(:, 2);
  base_subdir = 'rwd-performance';
end

bfw_lda.plot_accuracy( perf, all_perf.labels' ...
  , 'mask_func', perf_mask_func ...
  , 'do_save', true ...
  , 'config', conf ...
  , 'base_subdir', base_subdir ...
);

%%  plot sig

use_gaze = true;

perf_mask_func = @(l, m) fcat.mask( l, m ...
  , @find, {'each-region-session'} ...
);

if ( use_gaze )  
  ps = all_perf.ps(:, 1);
  base_subdir = 'gaze-performance';
else
  perf_mask_func = @(l, m) intersect(perf_mask_func(l, m) ...
    , find(l, ref(combs(l, 'roi-pairs', m), '()', 1)) ...
  );

  ps = all_perf.ps(:, 2);
  base_subdir = 'rwd-performance';
end

bfw_lda.plot_proportion_sig_sessions( ps, all_perf.p_labels' ...
  , 'mask_func', perf_mask_func ...
  , 'do_save', true ...
  , 'config', conf ...
  , 'base_subdir', base_subdir ...
);


