data_root = '/Volumes/external/data/changlab/brains/free_viewing';

spike_data = bfw_pm.load_spike_data( data_root );
%%

labels = fcat.from( spike_data.save_spike_labels );
to_replace = { 'm1noneyesface', 'm1object', 'm1outside1', 'm1eyes' };
replace_with = { 'non_eye_face', 'nonsocial_object', 'outside1', 'eyes_nf' };

eachcell( @(x, y) replace(labels, x, y), to_replace, replace_with );

%%

use_binned = false;
bin_size = 5;

psth = spike_data.spike_dat;
t = spike_data.t;

if ( use_binned )
  inds = shared_utils.vector.slidebin( 1:numel(t), bin_size, bin_size );
  t = cellfun( @(x) t(x(1)), inds );

  tmp_psth = nan( rows(psth), numel(inds) );
  for i = 1:numel(inds)
    tmp_psth(:, i) = nanmean( psth(:, inds{i}), 2 );
  end
  psth = tmp_psth;
end

outs = bfw_ct.anova_over_time( psth, labels', t ...
  , 'time_windows', {[0, 0.3], [-0.3, 0], [-0.3, 0.3]} ...
  , 'exclusive_end_range', [false, true, false] ...
  , 'flip_range', [false, true, false] ...
  , 'min_num_consecutive_significant', 5 ...
  , 'mask_func', @(labels, mask) find(labels, {'eyes_nf', 'non_eye_face'}, mask) ...
);

%%

min_ts = outs.min_ts;
min_labels = outs.min_labels';

pl = plotlabeled.make_common();

fcats = { 'time_window' };
pcats = [ {'region'}, fcats ];

[figs, axs] = pl.figures( @hist, min_ts, min_labels', fcats, pcats, 1e2 );