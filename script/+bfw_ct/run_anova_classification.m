% source_dir = '09062019_eyes_v_non_eyes_face';
% source_dir = 'revisit_09032019';
% source_dir = '091119_nsobj_eyes_matched';
% source_dir = '091219_ns_obj_non_collapsed_eyes_matched';
% source_dir = 

source_dir = '01152019-cc-spikes';

base_load_p = fullfile( bfw.dataroot() ...
  , 'analyses/spike_lda/reward_gaze_spikes' ...
  , source_dir ...
);

%%

gaze_counts = shared_utils.io.fload( fullfile(base_load_p, 'gaze_counts.mat') );

%%

counts = gaze_counts;
% t_window = [-1, -0.7];
t_window = [0, 0.25];
base_subdir = sprintf( '%d_%d', t_window*1e3 );

t_ind = counts.t >= t_window(1) & counts.t <= t_window(2);
counts.spikes = nanmean( counts.spikes(:, t_ind), 2 );

anova_outs = bfw_ct.anova_classification( counts ...
  , 'do_save', true ...
  , 'base_subdir', base_subdir ...
  , 'post_hoc_denominator_significant_cells', false ...
  , 'mask_func', @(labels) findnone(labels, 'face') ...
);

%%

mask_func = @(labels) findnone( labels, 'face' );

pre_win = [-0.3, 0];
post_win = [0, 0.3];

pre_spikes = nanmean( gaze_counts.spikes(:, mask_gele(gaze_counts.t, pre_win(1), pre_win(2))), 2 );
post_spikes = nanmean( gaze_counts.spikes(:, mask_gele(gaze_counts.t, post_win(1), post_win(2))), 2 );

pre_counts = setfield( gaze_counts, 'spikes', pre_spikes );
post_counts = setfield( gaze_counts, 'spikes', post_spikes );

anova_outs_pre = bfw_ct.anova_classification( pre_counts, 'mask_func', mask_func );
anova_outs_post = bfw_ct.anova_classification( post_counts, 'mask_func', mask_func );

%%

do_save = true;
assert( anova_outs_pre.summary_labels == anova_outs_post.summary_labels, 'Labels mismatch' );

summary_labels = anova_outs_pre.summary_labels';
addcat( summary_labels, 'epoch' );

only_pre = anova_outs_pre.is_sig & ~anova_outs_post.is_sig;
only_post = ~anova_outs_pre.is_sig & anova_outs_post.is_sig;

pre_and_post = anova_outs_pre.is_sig & anova_outs_post.is_sig;
pre_or_post = anova_outs_pre.is_sig | anova_outs_post.is_sig;

sets = { only_pre, only_post, pre_and_post, pre_or_post };
epoch_labels = { 'only_pre', 'only_post', 'pre_and_post', 'pre_or_post' };

region_I = findall( summary_labels, {'region', 'main_effect'} );
prop_labels = fcat();
props = zeros( numel(region_I) * numel(sets), 1 );
stp = 1;

for i = 1:numel(region_I)  
  for j = 1:numel(sets)
    append1( prop_labels, summary_labels, region_I{i} );
    setcat( prop_labels, 'epoch', epoch_labels{j}, rows(prop_labels) );
    props(stp) = pnz( sets{j}(region_I{i}) );
    stp = stp + 1;
  end
end

pl = plotlabeled.make_common();
axs = pl.bar( props, prop_labels, 'epoch', 'region', 'main_effect' );

if ( do_save )
  save_p = fullfile( bfw.dataroot(), 'plots', 'cell_type_classification' ...
    , dsp3.datedir, base_subdir, 'pre_vs_post' );
  dsp3.req_savefig( gcf, save_p, prop_labels, 'region' );
end





