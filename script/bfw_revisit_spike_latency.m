conf = bfw.set_dataroot( 'C:\data\bfw' );
rois = {'eyes_nf', 'face', 'right_nonsocial_object' ...
  , 'right_nonsocial_object_eyes_nf_matched', 'everywhere'};
bfw_gather_aligned_spikes( ...
    'rois', rois ...
  , 'preserve_output', false ...
  , 'output_directory', 'aligned_spikes' ...
  , 'config', conf ...
  , 'events_subdir', 'raw_events_remade' ...
  , 'is_parallel', true ...
  , 'overwrite', true ...
);

%%

conf = bfw.set_dataroot( 'C:\data\bfw', bfw.config.load() );
aligned_spike_files = shared_utils.io.findmat( bfw.gid('aligned_spikes', conf) );

labs = cell( numel(aligned_spike_files), 1 );
spikes = cell( size(labs) );
store_ts = cell( size(labs) );

parfor i = 1:numel(aligned_spike_files)
  shared_utils.general.progress( i, numel(aligned_spike_files) );
  spike_file = shared_utils.io.fload( aligned_spike_files{i} );
  labs{i} = spike_file.labels;
  spikes{i} = spike_file.spikes;
  store_ts{i} = spike_file.t;
end

%%

t = store_ts{1};

%%

src_labels = vertcat( fcat, labs{:} );
all_spikes = vertcat( spikes{:} );

[src_labels, transform_ind] = bfw.make_whole_face_roi( src_labels );
all_spikes = all_spikes(transform_ind, :);

%%

cell_id_mat = bfw_load_cell_id_matrix();
all_labels = bfw.apply_new_cell_id_labels( src_labels', cell_id_mat );

%%

mask_func = @(l, m) pipe(m ...
  , @(m) find(l, 'm1', m) ...
);

%%  baseline means

mask = mask_func( all_labels, findnone(all_labels, {'whole_face'}) );
[baseline_labs, baseline_I] = keepeach( all_labels', 'unit_uuid', mask );
baseline_means = bfw.row_mean( all_spikes, baseline_I );
baseline_means = mean( baseline_means, 2 );

%%

social_cells = bfw_ct.load_significant_social_cell_labels_from_anova( [], true );
roi_cells = bfw_ct.load_significant_roi_cell_labels_from_anova( [], true );
anova_cs = combs( social_cells, 'unit_uuid' );

%%  "latency" as N SEMS above / below mean

n_sems = 4;

% latency_each = { 'unit_uuid', 'roi', 'unified_filename' };
latency_each = { 'unit_uuid', 'roi' };
mask = mask_func( all_labels, rowmask(all_labels) );
% mask = findor( all_labels, anova_cs, mask );
[cond_labs, cond_I, cond_C] = keepeach( all_labels', latency_each, mask );

unit_I = findall( cond_labs, 'unit_uuid' );
for i = 1:numel(unit_I)
  if ( false )  % match eye and face counts
    eye_ind = find( cond_labs, 'eyes_nf', unit_I{i} );
    face_ind = find( cond_labs, 'face', unit_I{i} );
    assert( numel(eye_ind) == 1 && numel(face_ind) == 1 );

    eye_n = numel( cond_I{eye_ind} );
    face_n = numel( cond_I{face_ind} );
    n_match = min( eye_n, face_n );
    cond_I{eye_ind} = cond_I{eye_ind}(randperm(eye_n, n_match));
    cond_I{face_ind} = cond_I{face_ind}(randperm(face_n, n_match));
  end
  
  if ( false )  % match everywhere counts to minimum
    counts = cellfun( @numel, cond_I(unit_I{i}) );  
    everywhere_ind = find( cond_labs, 'everywhere', unit_I{i} );
    keep_n = min( counts );
    rand_sample = randperm( numel(cond_I{everywhere_ind}), keep_n );  
    cond_I{everywhere_ind} = cond_I{everywhere_ind}(rand_sample);
  end
end

row_means = bfw.row_mean( all_spikes, cond_I );

latencies = nan( numel(cond_I), 1 );
latency_inds = false( numel(latencies), numel(t) );

for i = 1:numel(cond_I)
  cond_subset = all_spikes(cond_I{i}, :);
  row_sem = plotlabeled.sem( cond_subset );
  row_mean = row_means(i, :);
  
  unit_id = cond_C{1, i};
  baseline_ind = find( baseline_labs, unit_id );
  baseline_mean = baseline_means(baseline_ind);
  assert( numel(baseline_ind) == 1 );
  
  above = row_mean >= baseline_mean + row_sem * n_sems;
  below = row_mean <= baseline_mean - row_sem * n_sems;
  either = above | below;
  latency_ind = find( either, 1 );
  
  if ( ~isempty(latency_ind) )
    latency = t(latency_ind);
    latencies(i) = latency;
    latency_inds(i, latency_ind:end) = true;
  end
end

%%  frequencies of cells with valid latencies

assert_ispair( latencies, cond_labs );

freq_mask = pipe( find(~isnan(latencies)) ...
  , @(m) findnone(cond_labs, 'everywhere', m) ...
);

[freq_labs, I, C] = keepeach( cond_labs', {'region', 'roi'}, freq_mask );
freqs = cellfun( @numel, I );
tbl = table( freqs );
tbl.Properties.RowNames = fcat.strjoin( C, ' | ' )';
[~, ind] = sort( tbl.Properties.RowNames );
tbl = tbl(ind, :);

if ( true )
  save_p = fullfile( bfw.dataroot(conf), 'plots/spike_latency', dsp3.datedir, 'latency_frequencies' );
  dsp3.req_writetable( tbl, save_p, cond_labs, {'region', 'roi'} );
end

%%  latency vs selectivity

auc_out = load_auc( bfw.config.load() );

contrasts = { ...
    {'whole_face', 'right_nonsocial_object', 'whole_face_nonsocial_object_whole_face_matched'} ...
  , {'eyes_nf', 'face', 'eyes_nf_face'} ...
  , {'eyes_nf', 'right_nonsocial_object_eyes_nf_matched', 'eyes_nf_nonsocial_object_eyes_nf_matched'} ...
};

assert_ispair( latencies, cond_labs );
auc_t_ind = auc_out.t >= 0 & auc_out.t < 0.5;

each_I = findall( cond_labs, 'region' );

contrast_labs = fcat();
all_aucs = [];
all_lats = [];

is_abs_lat = false;
is_abs_auc = true;

for i = 1:numel(contrasts)
  cs = contrasts{i};
  
  for idx = 1:numel(each_I)
    lat_units = combs( cond_labs, 'unit_uuid', each_I{idx} );

    ia = find_combinations( cond_labs, lat_units, find(cond_labs, cs{1}) );
    ib = find_combinations( cond_labs, lat_units, find(cond_labs, cs{2}) );
    ic = find_combinations( auc_out.labels, lat_units, find(auc_out.labels, cs{3}) );

    lat_diffs = mean_differences( latencies, ia, ib );    
    subset_aucs = cellfun( @(x) auc_out.auc(x, :), ic, 'un', 0 );
    
%     aucs = cellfun( @(x) nanmean(x, 2), subset_aucs );
    aucs = cellfun( @(x) max(x, [], 2), subset_aucs );
    aucs = aucs - 0.5;
    
    if ( is_abs_lat )
      lat_diffs = abs( lat_diffs );
    end
    if ( is_abs_auc )
      aucs = abs( aucs );
    end
    
    cont_labs = append1( fcat, cond_labs, find(cond_labs, cs(1:2), each_I{idx}), numel(ic) );
    setcat( cont_labs, 'unit_uuid', lat_units );
    setcat( cont_labs, 'roi', sprintf('%s v %s', cs{1:2}) );
    
    all_aucs = [ all_aucs; aucs ];
    all_lats = [ all_lats; lat_diffs ];
    append( contrast_labs, cont_labs );
  end
end

%%  scatter latency vs selectivity

ki = find( ~isnan(all_aucs) & ~isnan(all_lats) );
reg_I = findall( contrast_labs, 'region', ki );
for i = 1:numel(reg_I)
  
ki = reg_I{i};

pl = plotlabeled.make_common();

[axs, ids] = pl.scatter( all_lats(ki), all_aucs(ki), contrast_labs(ki), {}, {'region', 'roi'} );
plotlabeled.scatter_addcorr( ids, all_lats(ki), all_aucs(ki) );

lat_lims = ternary( is_abs_lat, [0, 2], [-2, 2] );
auc_lims = ternary( is_abs_auc, [0, 0.5], [-0.5, 0.5] );
shared_utils.plot.set_xlims( axs, lat_lims );
shared_utils.plot.set_ylims( axs, auc_lims );

if ( true )
  shared_utils.plot.fullscreen( gcf );
  save_p = fullfile( bfw.dataroot(conf), 'plots/spike_latency', dsp3.datedir, 'latency_v_selectivity' );
  dsp3.req_savefig( gcf, save_p, prune(contrast_labs(ki)), {'region', 'roi'} );
end

end

%%  stats for latency difference between regions

reg_C = combs( contrast_labs, 'region' );
pair_inds = bfw.pair_combination_indices( numel(reg_C) );
assert_ispair( all_lats, contrast_labs );

sig_cell_ind = find_significant_anova_cells( contrast_labs, social_cells );

sr_tables = {};
sr_labels = fcat();
for i = 1:size(pair_inds, 1)
  pind = pair_inds(i, :);
  ra = reg_C{pind(1)};
  rb = reg_C{pind(2)};
  
  res = dsp3.kstest2( all_lats, contrast_labs, {'roi'}, ra, rb ...
    , 'mask', findor(contrast_labs, {ra, rb}, sig_cell_ind) ...
  );

  setcat( res.sr_labels, 'region', sprintf('%s v %s', ra, rb) );
  append( sr_labels, res.sr_labels );
  sr_tables = [ sr_tables; res.sr_tables ];
end

sr_tables = vertcat( sr_tables{:} );

if ( false )
  row_names = fcat.strjoin( sr_labels(:, {'roi', 'region'})', ' | ' );
  sr_tables.Properties.RowNames = row_names;  
  save_p = fullfile( bfw.dataroot(conf) ...
    , 'plots/spike_latency', dsp3.datedir, 'latency_stats_between_regions' );
  dsp3.req_writetable( sr_tables, save_p, sr_labels, {'roi', 'region'} );
end

%%  stats for latency difference between sig and not sig

anova_labs = contrast_labs';
anova_cells = social_cells;
is_sig_cell = find( anova_labs, combs(anova_cells, 'unit_uuid', find(anova_cells, 'significant')) );
addsetcat( anova_labs, 'significant-cell', 'significant-cell-false' );
setcat( anova_labs, 'significant-cell', 'significant-cell-true', is_sig_cell );

res = dsp3.kstest2( all_lats, anova_labs, {'roi', 'region'} ...
  , 'significant-cell-true', 'significant-cell-false' ...
  , 'mask', find(~isnan(all_lats)) ...
);

sr_tables = vertcat( res.sr_tables{:} );
sr_labels = res.sr_labels';
row_names = fcat.strjoin( sr_labels(:, {'roi', 'region'})', ' | ' );
sr_tables.Properties.RowNames = row_names;

if ( true )
  save_p = fullfile( bfw.dataroot(conf) ...
    , 'plots/spike_latency', dsp3.datedir, 'latency_stats_between_sig_not_sig_anova_cells' );
  dsp3.req_writetable( sr_tables, save_p, sr_labels, {'roi', 'region'} );
end

%%  split latency by sig social cells

anova_labs = contrast_labs';

% anova_cells = roi_cells;
anova_cells = social_cells;

is_sig_cell = find( anova_labs, combs(anova_cells, 'unit_uuid', find(anova_cells, 'significant')) );
% is_sig_cell = rowmask( anova_labs );
addsetcat( anova_labs, 'significant-cell', 'significant-cell-false' );
setcat( anova_labs, 'significant-cell', 'significant-cell-true', is_sig_cell );

if ( true )
  to_plot = [ anova_labs'; anova_labs ];
  setcat( to_plot, 'significant-cell', 'significant-cell-false', 1:rows(anova_labs) );
  to_plot_lats = [ all_lats; all_lats ];
else
  to_plot = anova_labs';
  to_plot_lats = all_lats;
end

plot_hists = true;
do_save = true;
pl = plotlabeled.make_common();

if ( plot_hists )
  pl.hist_add_summary_line = true;
  pl.summary_func = @nanmedian;
  pl.y_lims = [0, 150];
%   [~, bc] = hist( all_lats, 20 );
  
  [figs, axs, I] = pl.figures( @hist, to_plot_lats, to_plot ...
    , {'region', 'roi'}, {'significant-cell', 'region', 'roi'}, bc );
  shared_utils.plot.set_xlims( axs, [-2, 2] );

  if ( do_save )
    for i = 1:numel(figs)
      shared_utils.plot.fullscreen( figs(i) );
      save_p = fullfile( bfw.dataroot(conf) ...
        , 'plots/spike_latency', dsp3.datedir, 'latency_hist' );
      dsp3.req_savefig( figs(i), save_p, prune(to_plot(I{i})), {'region', 'roi'} );
    end
  end
else
  axs = pl.bar( to_plot_lats, to_plot, 'region', 'significant-cell', 'roi' );
  ylabel( axs(1), 'Latency difference' );
  if ( do_save )
    shared_utils.plot.fullscreen( gcf );
    save_p = fullfile( bfw.dataroot(conf), 'plots/spike_latency', dsp3.datedir, 'latency_bar' );
    dsp3.req_savefig( gcf, save_p, to_plot, {'region', 'roi'} );
  end
end

%%  num props

[p_present_labs, lat_cond_I] = keepeach( cond_labs', 'roi' );
p_present = nan( size(lat_cond_I) );
for i = 1:numel(lat_cond_I)
  p_present(i) = pnz( ~isnan(latencies(lat_cond_I{i})) );
end

pl = plotlabeled.make_common();
pl.hist_add_summary_line = true;
pl.summary_func = @nanmedian;
axs = pl.bar( p_present, p_present_labs, 'roi', {}, {} );

%%  cum hist

assert_ispair( latency_inds, cond_labs );

% hist_mask = find( cond_labs, {'eyes_nf', 'whole_face', 'face'} );
hist_mask = findnone( cond_labs, {'everywhere'} );
[cum_labs, lat_cond_I] = keepeach( cond_labs', {'roi', 'region', 'mat_filename'}, hist_mask );
cum_props = to_cumuluative_proportion( latency_inds, lat_cond_I );

%%  latency stats between regions

anova_outs = dsp3.anovan2( latencies, cond_labs', {'roi'}, 'region' ...
  , 'mask', findnone(cond_labs, {'right_nonsocial_object_eyes_nf_matched'}) ...
  , 'only_significant_factor_comparisons', false ...
);
if ( true )
  save_p = fullfile( bfw.dataroot(conf), 'plots/spike_latency', dsp3.datedir, 'cum_hist/stats' );
  dsp3.save_anova_outputs( anova_outs, save_p, {'region', 'roi'} );
end

%%  latency differences between rois

contrasts = { ...
    {'whole_face', 'right_nonsocial_object'} ...
  , {'eyes_nf', 'face'} ...
  , {'eyes_nf', 'right_nonsocial_object_eyes_nf_matched'} ...
};

contrast_labs = fcat();
contrast_outs = {};
for i = 1:numel(contrasts)
  a = contrasts{i}{1};
  b = contrasts{i}{2};
  rs_outs = dsp3.ranksum( latencies, cond_labs', {'region'}, a, b ...
    , 'descriptive_funcs', dsp3.nandescriptive_funcs() ...
  );
  rs_labs = append1( fcat, cond_labs, find(cond_labs, {a, b}) );
  setcat( rs_labs, 'roi', sprintf('%s vs %s', a, b) );  
  setcat( rs_outs.rs_labels, 'roi', sprintf('%s vs %s', a, b) );
  contrast_outs{end+1, 1} = rs_outs;
  append( contrast_labs, rs_labs );
end

if ( true )
  for i = 1:numel(contrast_outs)
    save_p = fullfile( bfw.dataroot(conf), 'plots/spike_latency', dsp3.datedir, 'cum_hist/roi_stats' );
    dsp3.save_ranksum_outputs( contrast_outs{i}, save_p, {'region', 'roi'} );
  end
end

%%  plot cum hist, over runs

do_save = false;

assert_ispair( cum_props, cum_labs );
plt_mask = fcat.mask( cum_labs ...
  , @find, 'whole_face' ...
  , @findnone, 'position_11' ...
);

mat_names = combs( cum_labs, 'mat_filename' );
mat_ns = fcat.parse( mat_names, 'position_' );
assert( ~any(isnan(mat_ns)) );
[~, ord] = sort( mat_ns );

pl = plotlabeled.make_common();
pl.group_order = mat_names(ord);
pl.color_func = @jet;
pl.x = t;

plt_props = cum_props(plt_mask, :);
plt_labs = cum_labs(plt_mask);

[axs, hs] = pl.lines( plt_props, plt_labs, {'mat_filename'}, {'region', 'roi'} );

%%  area under cum hist

assert_ispair( cum_props, cum_labs );
plt_mask = fcat.mask( cum_labs ...
  , @find, 'whole_face' ...
  , @findnone, 'position_11' ...
);

[each_I, each_C] = findall( cum_labs, {'region', 'roi'}, plt_mask );
shp = plotlabeled.get_subplot_shape( numel(each_I) );

axs = gobjects( size(each_I) );
for i = 1:numel(each_I)
  [group_I, group_C] = findall( cum_labs, 'mat_filename', each_I{i} );
  assert( isequal(unique(cellfun(@numel, group_I)), 1) );
  
  mat_ns = fcat.parse( group_C(1, :), 'position_' );
  assert( ~any(isnan(mat_ns)) );
  [~, ord] = sort( mat_ns );
  group_I = group_I(ord);
  group_C = group_C(:, ord);
  
  areas = cat_expanded( 1, cellfun(@(x) trapz(cum_props(x, :)), group_I, 'un', 0) );
  
  ax = subplot( shp(1), shp(2), i );
  cla( ax ); hold( ax, 'on' );
  axs(i) = ax;
  h = plot( ax, 1:numel(areas), areas );
  
  X = columnize(1:numel(areas));
  Y = areas(:);
  [r, p] = corr( X, Y );
  poly_p = polyfit( X, Y, 1 );
  line_y = polyval( poly_p, X );
  plot( ax, X, line_y );
  
  text( ax, max(get(ax, 'xlim')), max(get(ax, 'ylim')) ...
    , sprintf('r = %0.2f, p = %0.2f', r, p) );
  
  title( strrep(strjoin(each_C(:, i), ' | '), '_', ' ') );
end

shared_utils.plot.match_xlims( axs );
shared_utils.plot.match_ylims( axs );

%%  plot cum hist

pl = plotlabeled.make_common();
pl.x = t;

plt_mask = findnone( cum_labs, 'right_nonsocial_object_eyes_nf_matched' );
plt_cum_props = cum_props(plt_mask, :);
plt_cum_labs = prune( cum_labs(plt_mask) );

axs = pl.lines( plt_cum_props, plt_cum_labs, {'region'}, {'roi'} );
arrayfun( @(x) axis(x, 'square'), axs, 'un', 0 );

if ( false )
  shared_utils.plot.fullscreen( gcf );
  save_p = fullfile( bfw.dataroot(conf), 'plots/spike_latency', dsp3.datedir, 'cum_hist' );
  dsp3.req_savefig( gcf, save_p, cum_labs, {'roi', 'region'} );
end

%%  plot cum hist, roi pairs

for i = 1:numel(contrasts)
  pl = plotlabeled.make_common();
  pl.x = t;

  plt_mask = find( cum_labs, contrasts{i} );
  plt_cum_props = cum_props(plt_mask, :);
  plt_cum_labs = prune( cum_labs(plt_mask) );

  axs = pl.lines( plt_cum_props, plt_cum_labs, {'roi'}, {'region'} );
  arrayfun( @(x) axis(x, 'square'), axs, 'un', 0 );

  if ( false )
    shared_utils.plot.fullscreen( gcf );
    save_p = fullfile( bfw.dataroot(conf), 'plots/spike_latency', dsp3.datedir, 'cum_hist_rois' );
    dsp3.req_savefig( gcf, save_p, plt_cum_labs, {'roi', 'region'} );
  end
end

%%

plt_mask = findnone( cond_labs, 'everywhere' );

plt_labs = cond_labs(plt_mask);
plt_latencies = latencies(plt_mask);
% plt_latencies(isnan(plt_latencies)) = 2;

pl = plotlabeled.make_common();
pl.hist_add_summary_line = true;
pl.summary_func = @nanmedian;
axs = pl.hist( plt_latencies, plt_labs, 'roi' );

%%  kw test between conditions

kw_each = { 'unit_uuid' };
contrasts = { ...
    {'whole_face', 'right_nonsocial_object'} ...
  , {'eyes_nf', 'face'} ...
  , {'eyes_nf', 'right_nonsocial_object_eyes_nf_matched'} ...
};

mask = mask_func( all_labels, rowmask(all_labels) );
[kw_labs, kw_I] = keepeach( all_labels', kw_each, mask );

test_labs = fcat();
test_ps = [];
test_inds = logical( [] );
test_lats = [];

p_thresh = 0.05;

for i = 1:numel(kw_I)
  shared_utils.general.progress( i, numel(kw_I) );
  
  cond_ind = kw_I{i};
  cont_labs = kw_labs(i);
  addcat( cont_labs, 'contrast' );
  
  for j = 1:numel(contrasts)
    cont = contrasts{j};
    
    ind0 = find( all_labels, cont{1}, cond_ind );
    ind1 = find( all_labels, cont{2}, cond_ind );
    group = [ zeros(size(ind0)); ones(size(ind1)) ];
    
    ps = zeros( 1, size(all_spikes, 2) );
    for k = 1:size(all_spikes, 2)
      set0 = all_spikes(ind0, k);
      set1 = all_spikes(ind1, k);
      X = [ set0; set1 ];
      ps(k) = kruskalwallis( X, group, 'off' );
    end
    
    p_ind = find( ps < p_thresh, 1 );
    
    test_ps(end+1, :) = ps;
    test_inds(end+1, :) = false( size(ps) );
    test_lats(end+1, 1) = nan;
    
    if ( ~isempty(p_ind) )
      test_inds(end, p_ind:end) = true;
      test_lats(end) = t(p_ind);
    end
    
    cont_lab = strjoin( cont, ' vs ' );
    setcat( cont_labs, 'contrast', cont_lab );
    append( test_labs, cont_labs );
  end
end

%%  stat for contrast latency differences

anova_outs = dsp3.anovan2( test_lats(:), test_labs', 'region', 'contrast' );

if ( true )
  save_p = fullfile( bfw.dataroot(conf), 'plots/spike_latency', dsp3.datedir, 'cum_hist_contrast/stats' );
  dsp3.save_anova_outputs( anova_outs, save_p, {'region', 'contrast'} );
end

%%  plot cumuluative contrasts

do_save = true;

assert_ispair( test_inds, test_labs );
[cum_labs, each_I] = keepeach( test_labs', {'region', 'contrast'} );
cum_props = to_cumuluative_proportion( test_inds, each_I );

pl = plotlabeled.make_common();
pl.x = t;

axs = pl.lines( cum_props, cum_labs, {'contrast'}, {'region'} );
arrayfun( @(x) axis(x, 'square'), axs, 'un', 0 );

if ( do_save )
  shared_utils.plot.fullscreen( gcf );
  save_p = fullfile( bfw.dataroot(conf), 'plots/spike_latency', dsp3.datedir, 'cum_hist_contrast' );
  dsp3.req_savefig( gcf, save_p, cum_labs, {'roi', 'region'} );
end

%%

function cum_props = to_cumuluative_proportion(indices, each_I)

cum_props = zeros( numel(each_I), size(indices, 2) );
for i = 1:numel(each_I)
  cell_subset = double(indices(each_I{i}, :));
  s = sum( cell_subset, 1 );
  num_non_empties = sum( any(cell_subset, 2) );
  cum_props(i, :) = s ./ num_non_empties;
end

end

function I = find_combinations(f, C, varargin)

I = cell( size(C, 2), 1 );
for i = 1:numel(I)
  I{i} = find( f, C(:, i), varargin{:} );
end

end

function d = mean_differences(data, ia, ib)

assert( numel(ia) == numel(ib) );
assert( iscolumn(data) );

d = nan( numel(ia), 1 );
for i = 1:numel(ia)
  d(i) = nanmean( data(ia{i}) ) - nanmean( data(ib{i}) );
end

end

function out = load_auc(conf)

step_size = 1e-2; % 10ms
look_back = -0.5;
look_ahead = 0.5;

auc_info = load( fullfile(bfw.dataroot(conf), 'analyses/auc/042121/session_auc.mat') );
session_auc = auc_info.session_auc;
t = look_back:step_size:look_ahead;

%%  concatenate

auc_info = vertcat( session_auc{:} );
auc = cat_expanded( 1, {auc_info.auc} );
auc_labels = cat_expanded( 1, {fcat, auc_info.auc_labels} );
auc_sig_info = cat_expanded( 1, {auc_info.auc_sig_info} );

bfw.apply_new_cell_id_labels( auc_labels, bfw_load_cell_id_matrix(conf) );
prune( auc_labels );

out = struct();
out.auc = auc;
out.labels = auc_labels;
out.sig_info = auc_sig_info;
out.t = t;

end

function sig_cell_ind = find_significant_anova_cells(target_labels, anova_labels)

sig_ids = combs( anova_labels, 'unit_uuid', find(anova_labels, 'significant') );
sig_cell_ind = find( target_labels, sig_ids );

end