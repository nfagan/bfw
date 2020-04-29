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

%{

anova hierarhy sig cells:

pre:        post:
[-500, 0], [0, 500];

either pre or post count as significant

level 1: whole-face vs. right nonsocial object whole face matched
level 2: non-eye face vs. eyes

spike density heat map

%}

gaze_counts = shared_utils.io.fload( '/Users/Nick/Desktop/bfw/analyses/spike_lda/reward_gaze_spikes/for_anova_class/gaze_counts.mat' );

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

% mask_func = @(labels) findnone( labels, 'face' );
mask_func = @(labels) rowmask(labels);

pre_win = [-0.5, 0];
post_win = [0, 0.5];

pre_spikes = nanmean( gaze_counts.spikes(:, mask_gele(gaze_counts.t, pre_win(1), pre_win(2))), 2 );
post_spikes = nanmean( gaze_counts.spikes(:, mask_gele(gaze_counts.t, post_win(1), post_win(2))), 2 );

pre_counts = setfield( gaze_counts, 'spikes', pre_spikes );
post_counts = setfield( gaze_counts, 'spikes', post_spikes );

anova_outs_pre = bfw_ct.anova_classification( pre_counts, 'mask_func', mask_func );
anova_outs_post = bfw_ct.anova_classification( post_counts, 'mask_func', mask_func );

%%

is_sig = @(outs, factor, alpha) outs.ps(:, ismember(outs.factors, factor)) < alpha;

alpha = 0.05;

pre_soc = is_sig( anova_outs_pre, 'social', alpha );
pre_roi = is_sig( anova_outs_pre, 'roi', alpha );
post_soc = is_sig( anova_outs_post, 'social', alpha );
post_roi = is_sig( anova_outs_post, 'roi', alpha );

is_sig_soc = pre_soc | post_soc;

add_non_sig_cat = @(l) addsetcat(l, 'is_significant', 'not_significant');
add_sig_labels = @(l, ind) setcat(l, 'is_significant', 'significant', find(ind));

soc_labs = add_non_sig_cat( anova_outs_pre.labels' );
add_sig_labels( soc_labs, is_sig_soc );
[soc_props, soc_prop_labels] = proportions_of( soc_labs, 'region', 'is_significant' );
addsetcat( soc_prop_labels, 'factor', 'social' );

roi_subset = pre_roi(is_sig_soc) | post_roi(is_sig_soc);
roi_subset_labs = add_non_sig_cat( anova_outs_pre.labels(find(is_sig_soc)) );
add_sig_labels( roi_subset_labs, roi_subset );
[roi_props, roi_prop_labels] = proportions_of( roi_subset_labs, 'region', 'is_significant' );
addsetcat( roi_prop_labels, 'factor', 'roi' );

%%

conf = bfw.set_dataroot( '~/Desktop/bfw' );
do_save = true;

pl = plotlabeled.make_common();
pl.pie_include_percentages = true;
pl.fig = figure(1);

pcats = {'region', 'factor'};
gcats = 'is_significant';

axs1 = pl.pie( soc_props*1e2, soc_prop_labels, gcats, pcats );

pl.fig = figure(2);
axs2 = pl.pie( roi_props*1e2, roi_prop_labels, gcats, pcats );

if ( do_save )
  figs = { figure(1), figure(2) };
  labs = { soc_prop_labels, roi_prop_labels };
  spec = csunion( pcats, gcats );
  
  for i = 1:numel(figs)
    save_p = fullfile( bfw.dataroot(conf), 'plots/anova_class/pie', dsp3.datedir );
    shared_utils.plot.fullscreen( figs{i} );
    dsp3.req_savefig( figs{i}, save_p, labs{i}, spec );
  end
end

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

% if ( do_save )
%   save_p = fullfile( bfw.dataroot(), 'plots', 'cell_type_classification' ...
%     , dsp3.datedir, base_subdir, 'pre_vs_post' );
%   dsp3.req_savefig( gcf, save_p, prop_labels, 'region' );
% end





