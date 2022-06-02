%%

conf = bfw.set_dataroot( 'C:\data\bfw' );
rois = { 'eyes_nf', 'face', 'right_nonsocial_object', 'right_nonsocial_object_eyes_nf_matched' };
ms = shared_utils.io.findmat( fullfile(bfw.gid(fullfile('sfcoherence', rois), conf)) );

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

do_sort = false;
src_reg_pairs = combs( coh_labels, 'region' );
src_regs = cellfun( @(x) strsplit(x, '_'), src_reg_pairs, 'un', 0 );
dst_regs = clean_region_pairs( src_regs, do_sort );

for i = 1:numel(src_reg_pairs)
  replace( coh_labels, src_reg_pairs{i}, dst_regs{i} );
end

[I, regs] = findall( coh_labels, 'region' );
split_regs = split_regions( regs );
set_spike_field_regions( coh_labels, split_regs, I );

[~, transform_ind] = bfw.make_whole_face_roi( coh_labels );
coh = coh(transform_ind, :, :);

%%  spectra

mask = pipe( rowmask(coh_labels) ...
  , @(m) findnone(coh_labels, ref_regions, m) ...
);

plot_spectra( coh, coh_labels, mask, f, t, {'roi', 'spk-region'}, 'region' ...
  , 'do_save', true, 'config', conf, 'clims', [0.65, 0.68] );

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

function dst_regs = clean_region_pairs(src_regs, do_sort)

regs = src_regs;
dst_regs = cell( size(src_regs) );
for i = 1:numel(regs)
  regs{i} = cellfun( @(x) strrep(x, 'accg', 'acc'), regs{i}, 'un', 0 );
  if ( do_sort )
    regs{i} = sort( regs{i} );
  end
  dst_regs{i} = strjoin( regs{i}, '_' );
end

end

function labels = set_spike_field_regions(labels, regions, I)

for i = 1:numel(regions)
  addsetcat( labels, 'spk-region', sprintf('spk-%s', regions{i}{1}), I{i} );
  addsetcat( labels, 'lfp-region', sprintf('lfp-%s', regions{i}{2}), I{i} );
end

prune( labels );

end

function pairs = split_regions(src_regs)
pairs = cellfun( @(x) strsplit(x, '_'), src_regs, 'un', 0 );
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
defaults.clims = [];
params = shared_utils.general.parsestruct( defaults, varargin );

pcats = csunion( pcats, fcats );

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
shared_utils.plot.set_clims( axs, params.clims );

if ( params.do_save )
  shared_utils.plot.fullscreen( gcf );
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