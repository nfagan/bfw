conf = bfw.set_dataroot( '~/Desktop/bfw' );

[gaze_counts, rwd_counts] = bfw_lda.load_gaze_reward_spikes( conf );

[~, gaze_ind] = bfw.make_whole_face_roi( gaze_counts.labels );

gaze_counts.events = gaze_counts.events(gaze_ind, :);
gaze_counts.spikes = gaze_counts.spikes(gaze_ind, :);

%%

select_func = ...
  @(spikes, t, twin) nanmean(spikes(:, mask_gele(t, twin(1), twin(2))), 2);

rois = categorical( gaze_counts.labels, 'roi' );
select_spikes_post = select_func( gaze_counts.spikes, gaze_counts.t, [0, 300] );
select_spikes_pre = select_func( gaze_counts.spikes, gaze_counts.t, [-300, 0] );

%%

combined_spikes = [ select_spikes_pre; select_spikes_post ];
combined_rois = [ rois; rois ];
combined_labels = addcat( gaze_counts.labels', 'epoch' );
repset( combined_labels, 'epoch', {'pre', 'post'} );

use_spikes = combined_spikes;
use_labels = combined_labels;

roi_order = {'eyes_nf', 'face', 'nonsocial_object'};
recode_as = { 'e', 'f', 'o' };

perm = perms(1:numel(roi_order));

mask = fcat.mask( use_labels ...
  , @find, roi_order ...
  , @find, 'm1' ...
  , @findnone, bfw.nan_unit_uuid ...
);

%   , @find, ref(combs(use_labels, 'unit_uuid'), '()', 1) ...

lm_each = { 'unit_uuid', 'region', 'session', 'epoch' };
[lm_labels, lm_I] = keepeach( use_labels', lm_each, mask );

cs = dsp3.numel_combvec( 1:rows(perm) );

par_beta_info = cell( size(cs, 2), 1 );
par_beta_labels = cell( size(par_beta_info) );

parfor idx = 1:size(cs, 2)
  shared_utils.general.progress( idx, size(cs, 2) );
  
  c = cs(:, idx);
  use_perm = perm(c(1), :);
  use_roi_order = roi_order(use_perm);
  roi_order_str = strjoin( recode_as(use_perm), '-' );
  
  curr_beta_info = ...
    bfw_lda.roi_linear_model_combinations( use_spikes, combined_rois, lm_I, use_roi_order );  
  curr_beta_labels = maybe_addsetcat( lm_labels', 'roi-order', roi_order_str );
  
  par_beta_info{idx} = curr_beta_info;
  par_beta_labels{idx} = curr_beta_labels;
end

par_beta_info = vertcat( par_beta_info{:} );
par_beta_labels = vertcat( fcat, par_beta_labels{:} );

%%

p_sig_each = union( setdiff(lm_each, {'unit_uuid', 'session'}), {'roi-order'} );
[p_sig_labels, p_sig_I] = keepeach( par_beta_labels', p_sig_each );
alpha = 0.05;

p_sigs = nan( size(p_sig_I) );

for i = 1:numel(p_sig_I)
  p_sigs(i) = pnz( par_beta_info(p_sig_I{i}, 2) < alpha );
end

%%

pl = plotlabeled.make_common();
pl.panel_order = { 'pre', 'post' };

axs = pl.bar( p_sigs, p_sig_labels, {'roi-order'}, 'region', 'epoch' );