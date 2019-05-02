function plot_decoding_timecourse(perf, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
params = bfw.parsestruct( defaults, varargin );

if ( isfield(perf, 'rg_outs') && ~isempty(perf.rg_outs) )
  plot_train_reward_test_gaze( perf.rg_outs, params );
end

if ( isfield(perf, 'gr_outs') && ~isempty(perf.gr_outs) )
  plot_train_gaze_test_reward( perf.gr_outs, params );
end

if ( isfield(perf, 'rr_outs') && ~isempty(perf.rr_outs) )
  plot_train_reward_test_reward( perf.rr_outs, params );
end

end

function plot_train_reward_test_reward(decode_outs, params)

gcats = { 'event-name' };
pcats = { 'region' };

mask = rowmask( decode_outs.labels );

plot_perf( decode_outs, {}, gcats, pcats, mask, 'train_reward_test_reward', params );

end

function plot_train_gaze_test_gaze(decode_outs, params)

xcats = { 'roi' };
gcats = {};
pcats = { 'region' };

mask = rowmask( decode_outs.labels );

plot_perf( decode_outs, xcats, gcats, pcats, mask, 'train_gaze_test_gaze', params );

end

function plot_train_reward_test_gaze(decode_outs, params)

gcats = { 'event-name' };
pcats = { 'roi', 'region' };
fcats = { 'region' };

mask = rowmask( decode_outs.labels );

plot_perf( decode_outs, fcats, gcats, pcats, mask, 'train_reward_test_gaze', params );

end

function plot_train_gaze_test_reward(decode_outs, params)

gcats = { 'roi' };
pcats = { 'event-name', 'region' };
fcats = { 'region' };

mask = rowmask( decode_outs.labels );

plot_perf( decode_outs, fcats, gcats, pcats, mask, 'train_gaze_test_reward', params );

end

function plot_perf(decode_outs, fcats, gcats, pcats, mask, subdir, params)

%%
labels = decode_outs.labels';
perf = decode_outs.performance;

pl = plotlabeled.make_common();
pl.x = decode_outs.t;

pltlabs = prune( labels(mask) );
pltdat = perf(mask, :);

[figs, axs, I] = pl.figures( @lines, pltdat, pltlabs, fcats, gcats, pcats );

shared_utils.plot.hold( axs, 'on' );
shared_utils.plot.add_horizontal_lines( axs, 0.5 );

if ( params.do_save )
  save_p = get_save_p( params, subdir );
  
  for i = 1:numel(I)
    shared_utils.plot.fullscreen( figs(i) );
    dsp3.req_savefig( figs(i), save_p, prune(pltlabs(I{i})), [pcats, fcats] );
  end
end

end

function save_p = get_save_p(params, varargin)

save_p = fullfile( bfw.dataroot(params.config), 'plots', 'cs_sens_vs_lda', dsp3.datedir ...
  , params.base_subdir, 'lines', varargin{:} );

end