function plot_per_unit_acorr_outs(acorr_outs, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
params = bfw.parsestruct( defaults, varargin );

labs = acorr_outs.labels';
bfw.unify_single_region_labels( labs );
base_mask = get_base_mask( labs );

% plot_contrast_scatters( acorr_outs, labs', base_mask, params );
% plot_unit_scatters( acorr_outs, labs', base_mask, params );
plot_per_unit_summary( acorr_outs, labs', base_mask, params );

end

function plot_contrast_scatters(acorr_outs, labs, base_mask, params)

%%
interval_spec = acorr_outs.params.interval_specificity;

scores = acorr_outs.osc_info(:, 2);

contrasts = { {'eyes_nf', 'mouth'}, {'eyes_nf', 'nonsocial_object'} };
contrast_spec = { 'unit_uuid', 'session', 'region' };

X = [];
pltdat = [];
pltlabs = fcat();

fig = gcf();

for i = 1:numel(contrasts)
  a = contrasts{i}{1};
  b = contrasts{i}{2};
  
  [contrast_dat, contrast_labs, I] = ...
    dsp3.summary_binary_op( scores, labs', contrast_spec, a, b, @minus, @nanmean, base_mask );
  
  setcat( contrast_labs, 'roi', sprintf('%s-%s', a, b) );
  
  tmp_x = repmat( i, size(contrast_dat) );
  
  append( pltlabs, contrast_labs );
  pltdat = [ pltdat; contrast_dat ];
  X = [ X; tmp_x ];
end

pcats = { 'region' };
gcats = interval_spec;

pl = plotlabeled.make_common();
pl.marker_size = 10;

axs = pl.scatter( X, pltdat, pltlabs, gcats, pcats );
shared_utils.plot.hold( axs, 'on' );
shared_utils.plot.set_xlims( axs, [0, numel(contrasts)+1] );
shared_utils.plot.add_horizontal_lines( axs, 0 );

if ( params.do_save )
  shared_utils.plot.fullscreen( fig );
  save_p = get_plot_p( params, 'contrast_scatters' );
  dsp3.req_savefig( fig, save_p, pltlabs, pcats );
end

end

function plot_unit_scatters(acorr_outs, labs, base_mask, params)

interval_spec = acorr_outs.params.interval_specificity;

X = acorr_outs.osc_info(base_mask, 1);
Y = acorr_outs.osc_info(base_mask, 2);

pcats = { 'region' };
gcats = interval_spec;

fig = gcf();

pl = plotlabeled.make_common();
pl.marker_size = 10;
pltlabs = prune( labs(base_mask) );

axs = pl.scatter( X, Y, pltlabs, gcats, pcats );

if ( params.do_save )
  shared_utils.plot.fullscreen( fig );
  save_p = get_plot_p( params, 'scatters' );
  dsp3.req_savefig( fig, save_p, pltlabs, pcats );
end

end

function plot_per_unit_summary(acorr_outs, labs, base_mask, params)

interval_spec = acorr_outs.params.interval_specificity;

fig_cats = {'unit_uuid', 'region'};

[unit_I, unit_C] = findall( labs, fig_cats, base_mask );
fig = figure( 1 );

for i = 1:numel(unit_I)  
  shared_utils.general.progress( i, numel(unit_I) );
  unit_combs = unit_C(:, i);
  region_name = unit_combs{2};
  
  [fig_I, fig_C] = findall( labs, interval_spec, unit_I{i} );
  n_combs = numel( fig_I );
  
  h_psths = gobjects( 0 );
  h_acorrs = gobjects( 0 );
  h_psds = gobjects( 0 );
  axs = gobjects( 0 );
  
  clf( fig );
  subp_shape = [ 1, 5 ];
  
  for j = 1:numel(fig_I)    
    ax = subplot( subp_shape(1), subp_shape(2), 1 );
    axs(1) = ax;
    
    row = fig_I{j};
    
    t = acorr_outs.acorr_bin_centers(row, :);
    acorr = acorr_outs.acorr(row, :);
    acorr_with_peak = acorr_outs.acorr_with_peak(row, :);
    osc_info = acorr_outs.osc_info(row, :);
    
    psth_t = acorr_outs.psth_t(row, :);
    psth_trace = smoothdata( acorr_outs.psth(row, :) );
    
    psd = smoothdata( acorr_outs.psd(row, :) );
    freqs = acorr_outs.f(1, :);
    
    f_ind = freqs <= acorr_outs.params.freq_window(2);
    freqs = freqs(f_ind);
    psd = psd(:, f_ind);
    
    h_psths(j) = plot( ax, psth_t, psth_trace );
    hold( ax, 'on' );
    
    ax = subplot( subp_shape(1), subp_shape(2), 2 );
    axs(2) = ax;
    
    plot( ax, t, acorr_with_peak );
    hold( ax, 'on' );
    h_acorrs(j) = plot( ax, t, acorr, 'linewidth', 1 );
    ylabel( ax, 'Acorr trace' );
    
    ax = subplot( subp_shape(1), subp_shape(2), 3 );
    axs(3) = ax;
    
    hold( ax, 'on' );
    h_psds(j) = plot( ax, freqs, psd, 'linewidth', 1 );
    set( ax, 'yscale', 'log' );
    ylabel( ax, 'Power spectra' );
    
    ax = subplot( subp_shape(1), subp_shape(2), 4 );
    axs(4) = ax;
    hold( ax, 'on' );
    bar( j, osc_info(1) );
    ylabel( ax, 'Oscillation frequeny' );
    
    ax = subplot( subp_shape(1), subp_shape(2), 5 );
    axs(5) = ax;
    hold( ax, 'on' );
    bar( j, osc_info(2) );
    ylabel( ax, 'Oscillation score' );
  end
  
  title_str = strrep( fcat.strjoin(unit_combs, ' | '), '_', ' ' );
  title( axs(1), title_str );
  
  group_str = strrep( fcat.strjoin(fig_C), '_', ' ' );
  legend( h_acorrs, group_str );
  legend( h_psds, group_str );
  legend( h_psths, group_str );
  
  for j = 4:5
    set( axs(j), 'xtick', 1:n_combs );
    set( axs(j), 'xticklabels', group_str );
  end
  
  if ( params.do_save )
    pltlabs = prune( labs(unit_I{i}) );
    shared_utils.plot.fullscreen( fig );
    save_p = get_plot_p( params, 'per_unit_summary', region_name );
    dsp3.req_savefig( fig, save_p, pltlabs, fig_cats );
  end
end

end

function plot_p = get_plot_p(params, varargin)

plot_p = fullfile( bfw.dataroot(params.config), 'plots', 'spike_osc' ...
  , dsp3.datedir, params.base_subdir, varargin{:} );

end

function base_mask = get_base_mask(labels)

base_mask = findnone( labels, bfw.nan_unit_uuid() );

end