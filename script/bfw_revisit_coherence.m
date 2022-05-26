%%

conf = bfw.set_dataroot( 'C:\data\bfw' );
rois = { 'eyes_nf', 'face', 'right_nonsocial_object' };
ms = shared_utils.io.findmat( fullfile(bfw.gid(fullfile('coherence', rois), conf)) );

coh_labels = cell( numel(ms), 1 );
coh = cell( size(coh_labels) );
time_freq = cell( size(coh_labels) );

parfor i = 1:numel(ms)
  coh_file = shared_utils.io.fload( ms{i} );
  coh_labels{i} = fcat.from( coh_file.labels, coh_file.categories );
  coh{i} = coh_file.data;
  time_freq{i} = {coh_file.f, coh_file.t};
end

coh = vertcat( coh{:} );
coh_labels = vertcat( fcat, coh_labels{:} );
f = time_freq{1}{1};
t = time_freq{1}{2};

src_reg_pairs = combs( coh_labels, 'region' );
src_regs = cellfun( @(x) strsplit(x, '_'), src_reg_pairs, 'un', 0 );
dst_regs = clean_region_pairs( src_regs );

for i = 1:numel(src_reg_pairs)
  replace( coh_labels, src_reg_pairs{i}, dst_regs{i} );
end

[~, transform_ind] = bfw.make_whole_face_roi( coh_labels );
coh = coh(transform_ind, :, :);

%%  spectra

mask = pipe( rowmask(coh_labels) ...
  , @(m) findnone(coh_labels, ref_regions, m) ...
);

plot_spectra( coh, coh_labels, mask, f, t, 'roi', {'region', 'roi'} ...
  , 'do_save', true, 'config', conf );

%%  lines

[band_means, band_labels] = dsp3.get_band_means( coh, coh_labels', f, dsp3.get_bands('map') );

mask = pipe( rowmask(band_labels) ...
  , @(m) findnone(band_labels, ref_regions, m) ...
  , @(m) find(band_labels, {'beta', 'gamma'}, m) ...
);

plot_lines( band_means, band_labels, mask, t, {'roi'}, {'bands'}, {'region', 'roi'} ...
  , 'do_save', true, 'config', conf );

%%  trial level hist

time_means = squeeze( mean(coh(:, :, t >= 0 & t < 0.5), 3) );
[band_means, band_labels] = dsp3.get_band_means( time_means, coh_labels', f, dsp3.get_bands('map') );

mask = pipe( rowmask(band_labels) ...
  , @(m) findnone(band_labels, ref_regions, m) ...
  , @(m) find(band_labels, {'beta', 'gamma'}, m) ...
);

plot_hists( band_means, band_labels, mask, {'roi', 'bands'}, {'region', 'roi', 'bands'} ...
  , 'do_save', true, 'config', conf );

%%

function regs = ref_regions()
regs = { 'bla_ref', 'ofc_ref', 'dmpfc_ref', 'acc_ref' };
end

function dst_regs = clean_region_pairs(src_regs)

regs = src_regs;
dst_regs = cell( size(src_regs) );
for i = 1:numel(regs)
  regs{i} = cellfun( @(x) strrep(x, 'accg', 'acc'), regs{i}, 'un', 0 );
  regs{i} = sort( regs{i} );
  dst_regs{i} = strjoin( regs{i}, '_' );
end

for i = 1:numel(src_regs)
  
end

end

function plot_lines(band_means, band_labels, mask, x, fcats, gcats, pcats, varargin)

defaults = struct();
defaults.do_save = false;
defaults.config = bfw.config.load();
params = shared_utils.general.parsestruct( defaults, varargin );

fig_I = findall( band_labels, fcats, mask );

for i = 1:numel(fig_I)
  
fi = fig_I{i};

pl = plotlabeled.make_common();
pl.panel_order = sort( combs(band_labels, 'region', mask) );
pl.add_errors = false;
pl.x = x;

plt = band_means(fi, :);
plt_labels = prune( band_labels(fi) );
axs = pl.lines( plt, plt_labels, gcats, pcats );
shared_utils.plot.set_ylims( axs, [0.66, 0.9] );

if ( params.do_save )
  save_p = fullfile( bfw.dataroot(params.config), 'plots/coherence/lines', dsp3.datedir );
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, plt_labels, pcats );
end

end

end

function plot_spectra(coh, coh_labels, mask, f, t, fcats, pcats, varargin)

defaults = struct();
defaults.do_save = false;
defaults.config = bfw.config.load();
params = shared_utils.general.parsestruct( defaults, varargin );

fig_I = findall( coh_labels, fcats, mask );

for i = 1:numel(fig_I)
  
fi = fig_I{i};

pl = plotlabeled.make_spectrogram( f, t );
pl.panel_order = sort( combs(coh_labels, 'region', mask) );

plt = coh(fi, :, :);
plt_labels = prune( coh_labels(fi) );
axs = pl.imagesc( plt, plt_labels, pcats );

shared_utils.plot.tseries_xticks( axs, t, 5 );
shared_utils.plot.fseries_yticks( axs, flip(round(f)), 5 );
shared_utils.plot.set_clims( axs, [0.67, 0.86] );

if ( params.do_save )
  save_p = fullfile( bfw.dataroot(params.config), 'plots/coherence/spectra', dsp3.datedir );
  dsp3.req_savefig( gcf, save_p, plt_labels, pcats );
end

end

end

function plot_hists(band_means, band_labels, mask, fcats, pcats, varargin)

defaults = struct();
defaults.do_save = false;
defaults.config = bfw.config.load();
params = shared_utils.general.parsestruct( defaults, varargin );

assert( isvector(band_means) );

fig_I = findall( band_labels, fcats, mask );

for i = 1:numel(fig_I)
  
fi = fig_I{i};

pl = plotlabeled.make_common();
pl.panel_order = sort( combs(band_labels, 'region', mask) );
pl.hist_add_summary_line = true;
pl.summary_func = @nanmedian;

plt = band_means(fi);
plt_labels = prune( band_labels(fi) );
axs = pl.hist( plt, plt_labels, pcats, 50 );
shared_utils.plot.set_xlims( axs, [0, 1] );

if ( params.do_save )
  save_p = fullfile( bfw.dataroot(params.config), 'plots/coherence/hist', dsp3.datedir );
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, plt_labels, pcats );
end

end

end