%%

conf = bfw.set_dataroot( 'C:\data\bfw' );
rois = { 'eyes_nf', 'face', 'right_nonsocial_object', 'right_nonsocial_object_eyes_nf_matched' };
ms = shared_utils.io.findmat( fullfile(bfw.gid(fullfile('sfcoherence', rois), conf)) );

[coh, coh_labels, f, t] = load_coh( ms );
clean_labels( coh_labels );

[~, transform_ind] = bfw.make_whole_face_roi( coh_labels );
coh = coh(transform_ind, :, :);

%%  re-run

conf = bfw.set_dataroot( 'C:\data\bfw' );
rois = { 'eyes_nf', 'face', 'right_nonsocial_object', 'right_nonsocial_object_eyes_nf_matched' };
ms = shared_utils.io.findmat( fullfile('C:\Users\nick\Downloads\tmp_share\tmp_share\', rois) );

[coh, coh_labels, f, t, event_times] = load_coh( ms );
clean_labels( coh_labels );

[~, transform_ind] = bfw.make_whole_face_roi( coh_labels );
coh = coh(transform_ind, :, :);
event_times = event_times(transform_ind);

[~, transform_ind] = bfw.make_whole_right_nonsocial_object_roi( coh_labels );
coh = coh(transform_ind, :, :);
event_times = event_times(transform_ind);

sort_each = { 'unified_filename', 'region', 'channel', 'unit_uuid' };

sort_I = findall( coh_labels, sort_each );
sort_ind = bfw.sort_order( event_times, sort_I );
event_times = event_times(sort_ind);
coh = coh(sort_ind, :, :);
coh_labels = coh_labels(sort_ind);

%%  n back label

curr_rois = {'eyes_nf', 'face', 'right_nonsocial_object_whole_face_matched'};

n_back_mask = pipe( rowmask(coh_labels) ...
  , @(m) find(coh_labels, 'm1', m) ...
  , @(m) find(coh_labels, curr_rois, m) ...
);

n_back_I = findall( coh_labels, sort_each, n_back_mask );
[curr_I, prev_I] = bfw.n_minus_n_indices( n_back_I, 1 );
addcat( coh_labels, 'prev-roi' );
for i = 1:numel(curr_I)
  prev_rois = cellstr( coh_labels, 'roi', prev_I{i} );
  prev_rois = eachcell( @(x) sprintf('prev-%s', x), prev_rois );
  setcat( coh_labels, 'prev-roi', prev_rois, curr_I{i} );
end

%%  n back matrix

bands = dsp3.get_bands( 'map' );
band_name = 'gamma';
band = bands(band_name);
tf_mean_coh = squeeze( nanmean(nanmean(coh(:, f >= band(1) & f <= band(2), t >= 0 & t <= 0.5), 2), 3) );

n_back_mask = pipe( rowmask(coh_labels) ...
  , @(m) find(coh_labels, 'm1', m) ...
  , @(m) find(coh_labels, curr_rois, m) ...
);

search_prev_rois = eachcell( @(x) sprintf('prev-%s', x), curr_rois );
[mat_labs, mat_I] = keepeach( coh_labels', 'region-pair', n_back_mask );
mats = make_n_back_matrix_coh( tf_mean_coh, coh_labels, mat_I, curr_rois, search_prev_rois );

%%  plot

mat_ind = 1;

plt_mats = mean_mats;
plt_mat_labs = mat_labs';

[mn, mx] = bounds( cat(3, plt_mats{:}), 'all' );

engage_mat = zeros( 3 );
engage_mat(contains(search_prev_rois, 'eyes_nf'), contains(curr_rois, 'eyes')) = 0;
engage_mat(contains(search_prev_rois, 'eyes_nf'), contains(curr_rois, 'object')) = -1;
engage_mat(contains(search_prev_rois, 'eyes_nf'), contains(curr_rois, 'face')) = -1;

engage_mat(contains(search_prev_rois, 'face'), contains(curr_rois, 'eyes')) = 1;
engage_mat(contains(search_prev_rois, 'face'), contains(curr_rois, 'face')) = 0;
engage_mat(contains(search_prev_rois, 'face'), contains(curr_rois, 'object')) = -1;

engage_mat(contains(search_prev_rois, 'object'), contains(curr_rois, 'eyes')) = 1;
engage_mat(contains(search_prev_rois, 'object'), contains(curr_rois, 'face')) = 1;
engage_mat(contains(search_prev_rois, 'object'), contains(curr_rois, 'object')) = 0;

soc_non_soc = zeros( 3 );
soc_non_soc(contains(search_prev_rois, 'eyes_nf'), contains(curr_rois, 'eyes')) = 0;
soc_non_soc(contains(search_prev_rois, 'eyes_nf'), contains(curr_rois, 'object')) = -1;
soc_non_soc(contains(search_prev_rois, 'eyes_nf'), contains(curr_rois, 'face')) = 0;

soc_non_soc(contains(search_prev_rois, 'face'), contains(curr_rois, 'eyes')) = 0;
soc_non_soc(contains(search_prev_rois, 'face'), contains(curr_rois, 'face')) = 0;
soc_non_soc(contains(search_prev_rois, 'face'), contains(curr_rois, 'object')) = -1;

soc_non_soc(contains(search_prev_rois, 'object'), contains(curr_rois, 'eyes')) = 1;
soc_non_soc(contains(search_prev_rois, 'object'), contains(curr_rois, 'face')) = 1;
soc_non_soc(contains(search_prev_rois, 'object'), contains(curr_rois, 'object')) = 0;

for i = 1:numel(plt_mats)

mat_ind = i;

ax = gca; cla( ax );

plt_mat = plt_mats{mat_ind};

if ( 1 )
  plt_mat(plt_mat >= 0) = mx;
  plt_mat(plt_mat < 0) = mn;
end

im = imagesc( ax, plt_mat );

mat_l = prune( plt_mat_labs(mat_ind) );
set( ax, 'xtick', 1:numel(search_prev_rois) ); 
set( ax, 'XTickLabel', strrep(search_prev_rois, '_', ' ') );
set( ax, 'ytick', 1:numel(curr_rois) ); 
set( ax, 'YTickLabel', strrep(curr_rois, '_', ' ') );
title( ax, strrep(strjoin([{band_name}, cellstr(mat_l, {'spk-region', 'region-pair'})], ' | '), '_' , ' ') );
% set( ax, 'CLim', [0.666, 0.674] );
set( ax, 'CLim', [mn, mx] );
colorbar;
colormap( 'jet' );

for j = 1:size(engage_mat, 1)
  for k = 1:size(engage_mat, 2)
    snc = soc_non_soc(j, k);
    switch ( snc )
      case 0
        snc_text = '';
      case 1
        snc_text = 'ns -> s';
      case -1
        snc_text = 's -> ns';
      otherwise
        error( 'xx' );
    end
    
    h = text( ax, j, k, sprintf('%d | (%s)', engage_mat(j, k), snc_text) );
    set( h, 'color', ones(1, 3) );
  end
end

if ( 1 )
  save_p = fullfile( bfw.dataroot(conf), 'plots/sfcoherence/nback', dsp3.datedir, band_name );
  dsp3.req_savefig( gcf, save_p, mat_l, {'spk-region', 'region-pair'} );
end

end

%%

bands = dsp3.get_bands( 'map' );
beta = bands('beta');
tf_mean_coh = squeeze( nanmean(nanmean(coh(:, f >= beta(1) & f <= beta(2), t >= 0 & t <= 0.5), 2), 3) );
out_I = findall( coh_labels, 'region-pair' );
is_outlier = detect_outliers( tf_mean_coh, out_I, 2.5 );
p_outliers = cellfun( @(x) pnz(is_outlier(x)), out_I );
non_outlier_inds = find( ~is_outlier );

%%  cs sf coherence

cs_ms = shared_utils.io.findmat( fullfile(bfw.gid(fullfile('sfcoherence', 'cs'), conf)) );
[cs_coh, cs_coh_labels, cs_f, cs_t] = load_coh( cs_ms );
clean_labels( cs_coh_labels );

%%  cs baseline mean sf coherence

match_each = {'session', 'region', 'channel', 'unit_uuid'};

cs_coh_mean = nanmean( cs_coh(:, :, cs_t >= 0 & cs_t <= 0.15), 3 );
[cs_base_labels, I] = keepeach( cs_coh_labels', match_each ...
  , find(cs_coh_labels, 'no-error') ...
);
cs_coh_mean = bfw.row_nanmean( double(cs_coh_mean), I );

%%  baseline normalize

[match_I, match_C] = findall( coh_labels, match_each );
base_I = bfw.find_combinations( cs_base_labels, match_C );
norm_coh = normalize_each( coh, cs_coh_mean, match_I, base_I, @minus );

%%

mask = pipe( rowmask(cs_coh_labels) ...
  , @(m) findnone(cs_coh_labels, ref_regions, m) ...
);

do_norm = false;
if ( do_norm )
  assert( false );
  clims = [-1e-2, 1e-2];
  plt_coh = cs_coh;
  subdir = 'normalized';
else
  clims = [0.65, 0.68];
  plt_coh = cs_coh;
  subdir = 'raw';
end

% subdir = sprintf( '%s-%s', subdir, strjoin(cellstr(looks_by), '_') );

% if ( rem_outliers )
%   mask = intersect( mask, non_outlier_inds );
%   subdir = sprintf( '%s-outliers-removed', subdir );
% end

plot_spectra( plt_coh, cs_coh_labels, mask, cs_f, cs_t, {'region-pair'}, {'spk-region'} ...
  , 'do_save', true, 'config', conf, 'clims', clims, 'subdir', subdir );

%%  spectra

coh_labels = site_coh_labels';
coh = site_coh;

looks_by = { 'm1' };
mask = pipe( rowmask(coh_labels) ...
  , @(m) findnone(coh_labels, ref_regions, m) ...
  , @(m) find(coh_labels, looks_by, m) ...
  , @(m) findor(coh_labels, {'lfp-bla', 'spk-bla'}, m) ...
);

if ( 1 )
  mask = find( coh_labels, 'has_cs_task__true', mask );
end

rem_outliers = false;
do_norm = false;
do_zscore = false;

if ( do_norm )
  clims = [-1e-2, 1e-2];
  plt_coh = norm_coh;
  subdir = 'normalized';
else
%   clims = [0.65, 0.68];
%   clims = [-7e-3, 7e-3];
%   clims = [-0.1, 0.1];
  clims = [];
  plt_coh = coh;
  subdir = 'raw';
end

subdir = sprintf( '%s-%s', subdir, strjoin(cellstr(looks_by), '_') );

if ( rem_outliers )
  mask = intersect( mask, non_outlier_inds );
  subdir = sprintf( '%s-outliers-removed', subdir );
end

plt_coh_labels = coh_labels;
% if ( do_zscore )
%   plt_coh = bfw.zscore_each( plt_coh, plt_coh_labels, {'channel', 'region', 'unit_uuid', '}
% end

plot_spectra( plt_coh, plt_coh_labels, mask, f, t, {'roi', 'region-pair'}, {'spk-region'} ...
  , 'do_save', true, 'config', conf, 'clims', clims, 'subdir', subdir, 'subdir_each', 'roi' ...
  , 'summary_func', @nanmean ...
);

%%  lines over frequency

[band_means, band_labels] = dsp3.get_band_means( coh, coh_labels', f, dsp3.get_bands('map') );

mask = pipe( rowmask(band_labels) ...
  , @(m) findnone(band_labels, ref_regions, m) ...
  , @(m) find(band_labels, {'beta', 'gamma'}, m) ...
  , @(m) findor(band_labels, {'lfp-bla', 'spk-bla'}, m) ...
  , @(m) find(band_labels, {'eyes_nf', 'face', 'whole_face', 'right_nonsocial_object_whole_face_matched'}, m) ...
);

plot_lines( band_means, band_labels, mask, t, {'bands'}, {'roi'}, {'region', 'bands'} ...
  , 'do_save', true, 'config', conf, 'y_lims', [-12e-3, 12e-3] );

%%  lines over time

coh_labels = site_coh_labels';
coh = site_coh;

t_coh0 = nanmean( coh(:, :, t >= -0.25 & t < 0), 3 );
t_coh1 = nanmean( coh(:, :, t >= 0 & t < 0.25), 3 );
t_coh = [ t_coh0; t_coh1 ];
t_coh_labels = repset( addcat(coh_labels', 'time_window'), 'time_window', {'[-250, 0]', '[0, 250]'} );

mask = pipe( rowmask(t_coh_labels) ...
  , @(m) findnone(t_coh_labels, ref_regions, m) ...
  , @(m) findor(t_coh_labels, {'lfp-bla', 'spk-bla'}, m) ...
  , @(m) find(t_coh_labels, {'eyes_nf', 'face', 'whole_face', 'right_nonsocial_object_whole_face_matched'}, m) ...
);

% lims = [0.63, 0.74];
lims = [-0.1, 0.1];
plot_lines( t_coh, t_coh_labels, mask, f, {'roi'}, {'region'}, {'roi', 'time_window'} ...
  , 'do_save', true, 'config', conf, 'y_lims', lims, 'summary_func', @nanmedian );

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

function plot_lines(band_means, band_labels, mask, x, fcats, gcats, pcats, varargin)

defaults = struct();
defaults.do_save = false;
defaults.config = bfw.config.load();
defaults.y_lims = [];
defaults.summary_func = @nanmean;
params = shared_utils.general.parsestruct( defaults, varargin );

fig_I = findall( band_labels, fcats, mask );

for i = 1:numel(fig_I)
  
fi = fig_I{i};

pl = plotlabeled.make_common();
pl.panel_order = sort( combs(band_labels, 'region', mask) );
pl.add_errors = false;
pl.x = x;
pl.summary_func = params.summary_func;

plt = band_means(fi, :);
plt_labels = prune( band_labels(fi) );
axs = pl.lines( plt, plt_labels, gcats, pcats );
shared_utils.plot.set_ylims( axs, params.y_lims );

if ( params.do_save )
  save_p = fullfile( bfw.dataroot(params.config), 'plots/coherence/lines', dsp3.datedir );
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, plt_labels, pcats );
end

end

end

function plot_spectra(coh, coh_labels, mask, f, t, fcats, pcats, varargin)

assert_ispair( coh, coh_labels );

defaults = struct();
defaults.do_save = false;
defaults.config = bfw.config.load();
defaults.clims = [];
defaults.subdir = '';
defaults.subdir_each = {};
defaults.summary_func = @nanmean;
params = shared_utils.general.parsestruct( defaults, varargin );

pcats = csunion( pcats, fcats );

[fig_I, fig_C] = findall( coh_labels, fcats, mask );

for i = 1:numel(fig_I)
  
shared_utils.general.progress( i, numel(fig_I) );  
fi = fig_I{i};

if ( ~isempty(params.subdir_each) )
  subdir_labs = strjoin( fcat.strjoin(combs(coh_labels, params.subdir_each, fi), '_'), '_' );
else
  subdir_labs = '';
end

pl = plotlabeled.make_spectrogram( f, t );
pl.panel_order = sort( combs(coh_labels, 'region', mask) );
pl.summary_func = params.summary_func;

plt = coh(fi, :, :);
plt_labels = prune( coh_labels(fi) );
axs = pl.imagesc( plt, plt_labels, pcats );

shared_utils.plot.tseries_xticks( axs, t, 5 );
shared_utils.plot.fseries_yticks( axs, flip(round(f)), 5 );
shared_utils.plot.set_clims( axs, params.clims );

if ( params.do_save )
  shared_utils.plot.fullscreen( gcf );
  save_p = fullfile( bfw.dataroot(params.config), 'plots/coherence/spectra', dsp3.datedir ...
    , params.subdir, subdir_labs );
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

function clean_labels(coh_labels)

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

sorted_regs = eachcell( @(x) sort(x), split_regs );
joined_regs = eachcell( @(x) sprintf('pair-%s', strjoin(x, '_')), sorted_regs );
for i = 1:numel(I)
  addsetcat( coh_labels, 'region-pair', joined_regs{i}, I{i} );
end

end

function [coh, coh_labels, f, t, evts] = load_coh(ms)

coh_labels = cell( numel(ms), 1 );
coh = cell( size(coh_labels) );
time_freq = cell( size(coh_labels) );
infos = cell( size(coh_labels) );

parfor i = 1:numel(ms)
  coh_file = shared_utils.io.fload( ms{i} );
  coh_labels{i} = fcat.from( coh_file.labels, coh_file.categories );
  coh{i} = coh_file.data;
  time_freq{i} = {coh_file.f, coh_file.t};
  infos{i} = coh_file.info;
end

coh = vertcat( coh{:} );
coh_labels = vertcat( fcat, coh_labels{:} );
f = time_freq{1}{1};
t = time_freq{1}{2};

if ( isfield(infos{1}, 'event_times') )
  evts = cate1( cellfun(@(x) x.event_times, infos, 'un', 0) );
  assert( numel(evts) == size(coh, 1) );
end

end

function normed = normalize_each(target, base, targ_I, base_I, op)

assert( numel(targ_I) == numel(base_I) );

normed = target;
for i = 1:numel(targ_I)
  mi = targ_I{i};
  bi = base_I{i};
  normed(mi, :, :) = op( target(mi, :, :), nanmean(base(bi, :, :), 1) );
end

end

function tf = detect_outliers(coh, out_I, n_devs)

validateattributes( coh, {'double', 'single'}, {'column'}, mfilename, 'coh' );

tf = false( size(coh) );
for i = 1:numel(out_I)
  oi = out_I{i};
  mu = nanmean( coh(oi) );
  sig = nanstd( coh(oi) );
  tf(oi) = (coh(oi) > mu + sig * n_devs) | (coh(oi) < mu - sig * n_devs);
end

end

function mats = make_n_back_matrix_coh(tf_mean_coh, coh_labels, mat_I, curr_rois, search_prev_rois)

validateattributes( tf_mean_coh, {'double', 'single'}, {'column'}, mfilename, 'tf_mean_coh' );
assert_ispair( tf_mean_coh, coh_labels );

mats = cell( numel(mat_I), 1 );

for i = 1:numel(mat_I)
  mi = mat_I{i};
  mat = nan( numel(curr_rois), numel(search_prev_rois) );
  for r = 1:numel(curr_rois)
    for c = 1:numel(search_prev_rois)
      ind = find( coh_labels, [curr_rois(r), search_prev_rois(c)], mi );
      mat(r, c) = nanmean( tf_mean_coh(ind) );
    end
  end
  mats{i} = mat;
end

end

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