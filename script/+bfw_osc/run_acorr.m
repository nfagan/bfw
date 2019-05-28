spikes_events = bfw_osc.gather_spikes_and_events();

%%

freq_window = [ 15, 25 ];

session_mask = find( spikes_events.meta_labs, {'01102019'} );
session_I = findall( spikes_events.meta_labs, 'session', session_mask );

acorr_outs = bfw_osc.acorr_main( spikes_events, session_I, 'freq_window', freq_window );

%%

acorr_filepath = fullfile( bfw.dataroot(), 'analyses', 'spike_osc', 'gamma', 'acorr_outs.mat' );
acorr_outs = shared_utils.io.fload( acorr_filepath );

%%

bfw_osc.plot_per_unit_acorr_outs( acorr_outs, 'do_save', false );

%%

scores = acorr_outs.osc_info(:, 2);
f_osc = acorr_outs.osc_info(:, 1);
labs = acorr_outs.labels';

bfw.unify_single_region_labels( labs );

mask = fcat.mask( labs ...
  , @find, {'bla', 'acc'} ...
  , @findnone, 'unit_uuid__NaN' ...
);

pl = plotlabeled.make_common();
xcats = { 'region' };
gcats = { 'roi' };
pcats = {};

pltdat = scores(mask);
pltlabs = prune( labs(mask) );

axs = pl.bar( pltdat, pltlabs, xcats, gcats, pcats );

%%
pcats = [ xcats, gcats ];

axs = pl.hist( f_osc(mask), labs(mask), pcats, 20 );

%%

psds = acorr_outs.psd;
labs = acorr_outs.labels';

mask = fcat.mask( labs ...
  , @find, {'bla', 'acc'} ...
  , @findnone, 'unit_uuid__NaN' ...
);

f = acorr_outs.f(1, :);
f_ind = f <= 70;

pl = plotlabeled.make_common();
pl.x = f(f_ind);

gcats = { 'roi' };
pcats = { 'region' };

axs = pl.lines( psds(mask, f_ind), labs(mask), gcats, pcats );

for i = 1:numel(axs)
  set( axs(i), 'yscale', 'log' );
end