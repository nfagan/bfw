function plot_train_reward_test_reward(decode_outs, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
params = bfw.parsestruct( defaults, varargin );

%%

labels = decode_outs.labels';
perf = decode_outs.performance;

pl = plotlabeled.make_common();

mask = fcat.mask( labels ...
  , @findnone, {} ...
);

% xcats = { 'roi' };
% gcats = { 'event-name' };
xcats = { 'reward-level' };
gcats = { 'event-name' };
pcats = { 'region' };

pl.x_order = { 'reward-1/reward-2', 'reward-2/reward-3' };

pltlabs = prune( labels(mask) );
pltdat = perf(mask);

axs = pl.bar( pltdat, pltlabs, xcats, gcats, pcats );

shared_utils.plot.hold( axs, 'on' );
shared_utils.plot.add_horizontal_lines( axs, 0.5 );

if ( params.do_save )
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, get_save_p(params), pltlabs, pcats );
end

end

function save_p = get_save_p(params)

save_p = fullfile( bfw.dataroot(params.config), 'plots', 'cs_sens_vs_lda', dsp3.datedir ...
  , 'train_reward_test_reward', params.base_subdir );

end