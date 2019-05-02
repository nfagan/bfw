function plot_decoding(perf, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
params = bfw.parsestruct( defaults, varargin );

%%

if ( isfield(perf, 'gg_outs') && ~isempty(perf.gg_outs) )
  plot_train_gaze_test_gaze( perf.gg_outs, params );
end

%%

if ( isfield(perf, 'rr_outs') && ~isempty(perf.rr_outs)  )
  plot_train_reward_test_reward( perf.rr_outs, params );
end

%%

if ( isfield(perf, 'rg_outs') && ~isempty(perf.rg_outs)  )
  plot_train_reward_test_gaze( perf.rg_outs, params );
end

%%

if ( isfield(perf, 'gr_outs') && ~isempty(perf.gr_outs)  )
  plot_train_gaze_test_reward( perf.gr_outs, params );
end

end

function plot_perf(decode_outs, xcats, gcats, pcats, mask, subdir, params)

%%
labels = decode_outs.labels';
perf = decode_outs.performance;

pl = plotlabeled.make_common();

pltlabs = prune( labels(mask) );
pltdat = perf(mask);

axs = pl.bar( pltdat, pltlabs, xcats, gcats, pcats );

shared_utils.plot.hold( axs, 'on' );
shared_utils.plot.add_horizontal_lines( axs, 0.5 );

if ( params.do_save )
  save_p = get_save_p( params, subdir );
  
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, pltlabs, pcats );
end

end

function plot_train_gaze_test_reward(decode_outs, params)

xcats = { 'roi' };
gcats = { 'event-name' };
pcats = { 'region' };

mask = rowmask( decode_outs.labels );

plot_perf( decode_outs, xcats, gcats, pcats, mask, 'train_gaze_test_reward', params );

end

function plot_train_reward_test_gaze(decode_outs, params)

xcats = { 'roi' };
gcats = { 'event-name' };
pcats = { 'region' };

mask = rowmask( decode_outs.labels );

plot_perf( decode_outs, xcats, gcats, pcats, mask, 'train_reward_test_gaze', params );

end

function plot_train_gaze_test_gaze(decode_outs, params)

%%

xcats = { 'roi' };
gcats = {};
pcats = { 'region' };

mask = rowmask( decode_outs.labels );

plot_perf( decode_outs, xcats, gcats, pcats, mask, 'train_gaze_test_gaze', params );

end

function plot_train_reward_test_reward(decode_outs, params)

%%

xcats = { 'reward-level' };
gcats = { 'event-name' };
pcats = { 'region' };

mask = rowmask( decode_outs.labels );

plot_perf( decode_outs, xcats, gcats, pcats, mask, 'train_reward_test_reward', params );

end

function save_p = get_save_p(params, varargin)

save_p = fullfile( bfw.dataroot(params.config), 'plots', 'cs_sens_vs_lda', dsp3.datedir ...
  , params.base_subdir, varargin{:} );

end