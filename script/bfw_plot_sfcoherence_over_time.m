%%

conf = bfw.set_dataroot( 'C:\data\bfw' );
rois = { 'free_viewing' };
ms = shared_utils.io.findmat( fullfile(bfw.gid(fullfile('sfcoherence', rois), conf)) );

[src_coh, coh_labels, f, t] = bfw.load_time_frequency_measure( ms );
bfw.clean_sfcoherence_labels( coh_labels );

%%  normalize

coh_norm_type = 'cs';

switch ( coh_norm_type )
  case 'minus_mean'
    norm_I = findall( coh_labels, {'session', 'lfp-region'} );
    mus = bfw.row_nanmean( double(src_coh), norm_I );
    coh = src_coh;
    for i = 1:numel(norm_I)
      ni = norm_I{i};
      coh(ni, :, :) = coh(ni, :, :) - mus(i, :, :);
    end

  case 'norm01'
    norm_I = findall( coh_labels, {'session', 'lfp-region'} );
    mins = cate1( rowifun(@(x) min(x, [], 1), norm_I, src_coh, 'un', 0) );
    maxs = cate1( rowifun(@(x) max(x, [], 1), norm_I, src_coh, 'un', 0) );
    coh = src_coh;
    for i = 1:numel(norm_I)
      ni = norm_I{i};
      span = rowref( maxs, i ) - rowref( mins, i );
      coh(ni, :, :) = (rowref(coh, ni) - rowref(mins, i)) ./ span;
    end

  case 'cs'
    [cs_I, cs_C] = findall( cs_coh_labels, {'session', 'channel', 'region', 'unit_uuid'} );
    coh_I = bfw.find_combinations( coh_labels, cs_C );
    coh = nan( size(src_coh) );
    cs_subset = nanmean( cs_coh(:, :, cs_t >= 0 & cs_t < 0.15), 3 );
    for i = 1:numel(coh_I)
      mean_cs = nanmean( cs_subset(cs_I{i}, :, :), 1 );
      coh(coh_I{i}, :, :) = src_coh(coh_I{i}, :, :) - mean_cs;
    end

  case 'none'
    coh = src_coh;

  otherwise
    error( 'Unrecognized coh norm type "%s".', coh_norm_type );
end

%%

% bin_step = 0.5; % must match value used to generate coherence over time.
bin_step = 2.5;
ds_factor = bin_step / 0.5;

mf = @(l, m) pipe(m ...
  , @(m) find(l, 'm1', m) ...
  , @(m) findor(l, {'right_nonsocial_object_whole_face_matched', 'whole_face', 'everywhere'}, m) ...
);

[look_freqs, freq_labels] = binned_look_frequencies( conf ...
 , 'bin_step', bin_step ...
 , 'mask_func', mf ...
 , 'duration_based', true ...
);

%%

[index_labs, index_I] = keepeach( freq_labels', 'unified_filename' );
setcat( index_labs, 'roi', 'face/obj' );

ind_a = eachcell( @(x) find(freq_labels, 'whole_face', x), index_I );
ind_b = eachcell( @(x) find(freq_labels, 'right_nonsocial_object_whole_face_matched', x), index_I );
freq_index = make_index( look_freqs, ind_a, ind_b );
smooth_index = smoothdata( freq_index, 2, 'movmean', 10 );

%%

un_I = findall( coh_labels, 'unified_filename' );
[coh_tcourse, coh_tcourse_labels] = make_coherence_timecourse( ...
  coh, coh_labels', un_I, size(look_freqs, 2), ds_factor );

%%  Identify ROI states above normalized frequency thresholds

smooth_freqs = smoothdata( look_freqs, 2, 'movmean', 10 );
prop_I = findall( freq_labels, 'unified_filename' );
roi_I = eachcell( @(x) findall(freq_labels, 'roi', x), prop_I );
% props = eachcell( @(x) to_normalized(smooth_freqs, x), roi_I );
props = eachcell( @(x) to_proportion(smooth_freqs, x), roi_I );
dst_props = rowdistribute( nan(size(smooth_freqs)), cate1(roi_I), cate1(props) );

state_threshs = 0.3:0.05:0.7;
min_state_dur = 1;

[sis, sdurs, tfs] = arrayfun( ...
  @(p) probability_based_state_indices(dst_props, p), state_threshs, 'un', 0 );
si_ends = eachcell( @(si, dur) cate1(eachcell(@(s, d) [s(:), d(:)], si, dur)), sis, sdurs );

si_labs = arrayfun( ...
  @(x) addsetcat(freq_labels', 'p-thresh', sprintf('p >= %0.3f', x)), state_threshs, 'un', 0 );
tot_si_labs = vertcat( fcat, si_labs{:} );
si_durs = cate1( eachcell(@(x) cellfun(@nanmean, x), sdurs) ) .* bin_step;
si_freqs = cate1( eachcell(@(durs) cellfun(@(dur) sum(dur * bin_step >= min_state_dur), durs), sdurs) );

pl = plotlabeled.make_common();
plot_cats = { {'roi'}, 'p-thresh', {} };

if ( 0 )
  plt_dat = si_freqs;
  lab = '# States per run';
else
  plt_dat = si_durs;
  lab = 'Mean state duration per run';
end

axs = pl.bar( plt_dat, tot_si_labs, plot_cats{:} );
ylabel( axs(1), lab );

%%  correlate looking proportions with individual sites

if ( 1 )
  use_props = smooth_index;
  use_behav_labels = index_labs';
else
  use_props = dst_props;
  use_behav_labels = freq_labels';
end

assert_ispair( use_props, use_behav_labels );

[site_I, site_C] = findall( coh_tcourse_labels ...
  , {'unified_filename', 'channel', 'unit_uuid'} );
assert( isequal(unique(cellfun(@numel, site_I)), 1) );
freq_I = bfw.find_combinations( freq_labels, site_C(1, :) );

bands = dsp3.get_bands( 'map' );
beta = bands('beta');
band = beta;
fi = f >= band(1) & f <= band(2);
freq_mean = squeeze( nanmean(coh_tcourse(:, fi, :, :), 2) );

corr_labs = fcat();
corr_stats = [];
for i = 1:numel(site_I)
  shared_utils.general.progress( i, numel(site_I) );
  si = site_I{i};
  sub_coh = freq_mean(si, :);
  mi = freq_I{i};
  for j = 1:numel(mi)
    props = use_props(mi(j), :);
    assert( isequal(size(props), size(sub_coh)) );
    [r, p] = corr( sub_coh(:), props(:) );
    corr_stats(end+1, :) = [r, p];
  end
  l = append( fcat, use_behav_labels, mi );
  join( l, coh_tcourse_labels(si) );
  append( corr_labs, l );
end

m = pipe( rowmask(corr_labs) ...
  , @(m) find_with_bla(corr_labs, m) ...
);

reg_I = findall( corr_labs, 'region' );
ps = corr_stats(:, 2);
props = cellfun( @(x) pnz(ps(x) < 0.05), reg_I );

%%  correlate looking proportions within regions - establish the input data

behav_type = 'raw_smoothed';

switch ( behav_type )
  case 'raw_smoothed'
    use_props = smooth_freqs;
    use_behav_labels = freq_labels';
  case 'proportions'
    use_props = dst_props;
    use_behav_labels = freq_labels';
  case 'index'
    use_props = smooth_index;
    use_behav_labels = index_labs';
  otherwise
    error( 'Unrecognized behav type "%s".', behav_type );
end

assert_ispair( use_props, use_behav_labels );
[site_I, site_C] = findall( coh_tcourse_labels, 'unified_filename' );
freq_I = bfw.find_combinations( use_behav_labels, site_C(1, :) );

[pair_I, pair_labs] = pair_looking_proportions_with_coherence(...
    use_behav_labels, freq_I ...
  , coh_tcourse_labels, site_I );

%%  correlate looking proportions within regions - run the correlation

bands = dsp3.get_bands( 'map' );
targ_band = 'beta';
band = bands(targ_band);
fi = f >= band(1) & f <= band(2);
freq_mean = squeeze( nanmean(coh_tcourse(:, fi, :, :), 2) );

targ_roi = 'right_nonsocial_object_whole_face_matched';
% targ_roi = 'whole_face';

m = pipe( rowmask(pair_labs) ...
  , @(m) find_with_bla(pair_labs, m) ...
  , @(m) find(pair_labs, targ_roi, m) ...
);
[corr_labs, reg_I, reg_C] = keepeach( ...
  pair_labs', {'roi', 'spk-region', 'lfp-region'}, m );
corr_stats = [];

axs = plots.cla( plots.panels(numel(reg_I)) );
for i = 1:numel(reg_I)
  ri = reg_I{i};
  li = pair_I(ri, 1);
  ci = pair_I(ri, 2);
  lin_props = columnize( use_props(li, :) );
  lin_coh = columnize( freq_mean(ci, :) );
  [r, p] = corr( lin_props, lin_coh, 'rows', 'complete', 'type', 'spearman' );
  corr_stats(end+1, :) = [r, p];
  
  no_nan = ~isnan(lin_props) & ~isnan(lin_coh);
  pol = polyfit( lin_props(no_nan), lin_coh(no_nan), 1 );
  scatter( axs(i), lin_props, lin_coh, 0.1 );
  title( axs(i), strrep(fcat.strjoin(reg_C(:, i), ' | '), '_', ' ') );
  if ( i == 1 )
    xlabel( axs(i), 'Looking proportion' );
    ylabel( axs(i), sprintf('%s coherence', targ_band) );
  end
  xs = get( axs(i), 'XTick' );
  ys = polyval( pol, xs );
  hold( axs(i), 'on' );
  plot( axs(i), xs, ys );
  sig_indicator = ternary( p < 0.05, ' (*)', '' );
  text( axs(i), xs(2), ys(end), sprintf('r=%0.3f, p=%0.3f%s', r, p, sig_indicator) );
%   xlim( axs(i), [-1, 1] ); 
  xlim( axs(i), [0, 1] ); 
%   ylim( axs(i), [0, 1] );
  ylim( axs(i), [-1, 1] );
end

[ti, rc] = tabular( corr_labs, 'region', 'roi' );
rps = cellfun( @(x) corr_stats(x, :), ti, 'un', 0 );
fcat.table( rps, rc{:} )

%%  example state

si = sis{1};
sdur = sdurs{1};

lots = findnone( freq_labels, 'whole_face', find(cellfun(@numel, si) >= 4) );
run_lab = cellstr( freq_labels, {'unified_filename'}, lots(1) );
ri = find( freq_labels, run_lab );
trace = dst_props(ri, :);

cla; hold off;
lab = strrep( fcat.strjoin(cellstr(freq_labels, 'roi', ri)'), '_', ' ' );

hs = {};
for i = 1:size(trace, 1)
  x = (0:size(trace, 2)-1) .* bin_step;
%   x = 1:size(trace, 2);
  
  h0 = plot( gca, x, trace(i, :), 'DisplayName', lab{i} ); hold on;
  ti = si{ri(i)};
  ti_end = ti + sdur{ri(i)} - 1;
  
  for j = 1:numel(ti)
    plt = x(ti(j):ti_end(j));
    if ( numel(plt) == 1 )
      h1 = plot( gca, plt, 1, 'k*' );
    else
      h1 = plot( gca, plt, ones(size(plt)), 'linewidth', 4 );
    end
    set( h1, 'color', get(h0, 'color') );
  end
  ylim( gca, [0, 1] );
  title( gca, strrep(run_lab, '_', ' ') );
  hs{i} = h0;
end
legend( vertcat(hs{:}) );

%%

bands = dsp3.get_bands( 'map' );
target_band = bands('beta');

f_ind = f >= target_band(1) & f <= target_band(2);
t_ind = t >= 0 & t <= 0;
tf_mean = squeeze( nanmean(nanmean(coh_tcourse(:, f_ind, t_ind, :), 2), 3) );

match_I = bfw.find_combinations( ...
  coh_tcourse_labels, cellstr(freq_labels, 'unified_filename')' );

state_mean_coh = [];
state_labs = fcat();
for i = 1:numel(sis)  
  shared_utils.general.progress( i, numel(sis) );
  [mean_coh, sub_labs] = state_averaged_coherence( ...
    sis{i}, sdurs{i}, si_labs{i}, tf_mean, coh_tcourse_labels, match_I );
  state_mean_coh = [ state_mean_coh; mean_coh ];
  append( state_labs, sub_labs );
end

%%  

plt_mask = pipe( rowmask(state_labs) ...
  , @(m) findor(state_labs, {'spk-bla', 'lfp-bla'}, m) ...
);

pl = plotlabeled.make_common();
plt_labs = state_labs(plt_mask);
replace( plt_labs, 'right_nonsocial_object_whole_face_matched', 'whole obj' );
axs = pl.bar( state_mean_coh(plt_mask), plt_labs ...
  , 'p-thresh', 'roi', {'spk-region', 'lfp-region'} );
shared_utils.plot.set_ylims( axs, [0.65, 0.69] );
ylabel( axs(1), 'SF Coherence' );

%%

freq_mask = pipe( rowmask(freq_labels) ...
  , @(m) find(freq_labels, 'run_number_1', m) ...
  , @(m) find(freq_labels, 'eyes_nf', m) ...
);

[freq_I, freq_C] = findall( freq_labels, {'unified_filename', 'roi'}, freq_mask );
match_I = bfw.find_combinations( coh_tcourse_labels, freq_C(1, :) );

bands = dsp3.get_bands( 'map' );
target_band = bands('gamma');

f_ind = f >= target_band(1) & f <= target_band(2);
t_ind = t >= 0 & t <= 0;
tf_mean = squeeze( nanmean(nanmean(coh_tcourse(:, f_ind, t_ind, :), 2), 3) );

for i = 1:numel(match_I)
  shared_utils.general.progress( i, numel(match_I) );
  
  mi = match_I{i};
  fi = freq_I{i};
  
  match_freqs = look_freqs(fi, :);
  match_freqs = smoothdata( match_freqs, 'movmean', 10 );
  match_freqs = match_freqs ./ max( match_freqs );
  
  xs = (0:size(match_freqs, 2)-1) .* bin_step;
  
  [coh_I, coh_C] = findall( coh_tcourse_labels, {'spk-region', 'lfp-region'}, match_I{i} );
  for j = 1:numel(coh_I)
    mi = coh_I{j};
    match_coh = tf_mean(mi, :);

    axs = plots.cla( plots.panels([2, 1]) );
    hf = plot( axs(1), xs, match_freqs );
    hcoh = plot( axs(2), xs, nanmean(match_coh, 1) );
    title( axs(1), strrep(strjoin(freq_C(:, i), ' | '), '_', ' ') );
    ylabel( axs(1), 'P look' );
    
    title( axs(2), strrep(strjoin(coh_C(:, j), ' | '), '_', ' ') );
    ylabel( axs(2), 'Beta coherence' );
    xlabel( axs(2), 'Time from run start (s)' );
    ylim( axs(1), [0, 1] );
    ylim( axs(2), [0, 1] );
    
    plt_coh_labs = prune( coh_tcourse_labels(mi) );
    join( plt_coh_labs, prune(freq_labels(fi)) );

    if ( 1 )
      reg_dir = strjoin( coh_C(:, j), '_' );
      save_p = fullfile( bfw.dataroot(conf), 'plots/sfcoherence/over_time', dsp3.datedir, reg_dir );
      shared_utils.plot.fullscreen( gcf );
      dsp3.req_savefig( gcf, save_p, plt_coh_labs, {'region', 'roi', 'unified_filename'} );
    end
  end
end

%%

function [coh_tcourse, coh_tcourse_labels] = ...
  make_coherence_timecourse(coh, coh_labels, each_I, num_cols, ds_factor)

assert_ispair( coh, coh_labels );

coh_tcourse = cell( numel(each_I), 1 );
coh_tcourse_labels = fcat();

for i = 1:numel(each_I)
  shared_utils.general.progress( i, numel(each_I) );
  
  chn_I = findall( coh_labels, {'channel', 'unit_uuid'}, each_I{i} );
  [tp_I, tp_C] = cellfun( ...
    @(x) findall(coh_labels, 'time-point', x), chn_I, 'un', 0 );
  assert( isequal(cellfun(@numel, tp_I), cellfun(@numel, chn_I)) );
  
  time_point_indices = cellfun( @(x) fcat.parse(x, 'tp-'), tp_C, 'un', 0 );
  max_ind = max( horzcat(time_point_indices{:}) );
  assert( max_ind <= num_cols * ds_factor );
  
  match_freqs = nan( numel(tp_I), size(coh, 2), size(coh, 3), num_cols * ds_factor );
  match_freq_labs = fcat();
  
  for j = 1:numel(tp_I)
    ti = tp_I{j};
    assert( isequal(unique(cellfun(@numel, ti)), 1) );
    for k = 1:numel(ti)
      match_freqs(j, :, :, time_point_indices{j}(k)) = coh(ti{k}, :, :);
    end  
    append1( match_freq_labs, coh_labels, vertcat(ti{:}) );
  end
  
  append( coh_tcourse_labels, match_freq_labs );
  coh_tcourse{i} = match_freqs;
end

coh_tcourse = vertcat( coh_tcourse{:} );
assert_ispair( coh_tcourse, coh_tcourse_labels )

if ( ds_factor ~= 1 )
  vi = shared_utils.vector.slidebin( 1:num_cols*ds_factor, ds_factor );
  assert( isequal(unique(cellfun('prodofsize', vi)), ds_factor) );
  dst_coh = cell( numel(vi), 1 );
  curr_sz = size( coh_tcourse );
  for i = 1:numel(vi)
    dst_coh{i} = reshape( ...
      nanmean(coh_tcourse(:, :, :, vi{i}), 4), curr_sz(1:3) );
  end
  coh_tcourse = cat( 4, dst_coh{:} );
end

end

function [look_freqs, freq_labels] = binned_look_frequencies(conf, varargin)

default_rois = {'whole_face', 'right_nonsocial_object_whole_face_matched'};

defaults = struct();
defaults.bin_step = 0.5;
% defaults.mask_func = @(l) pipe(rowmask(l) ...
%   , @(m) find(l, 'm1', m) ...
%   , @(m) findor(l, {'eyes_nf', 'right_nonsocial_object', 'right_nonsocial_object_eyes_nf_matched'}, m) ...
% );
defaults.mask_func = @(l, m) pipe(m ...
  , @(m) find(l, 'm1', m) ...
  , @(m) findor(l, default_rois, m) ...
);
defaults.duration_based = false;
params = shared_utils.general.parsestruct( defaults, varargin );

ps = bfw.matched_files( ...
    shared_utils.io.findmat(bfw.gid('meta', conf)) ...
  , bfw.gid('aligned_raw_samples/time', conf) ...
  , bfw.gid('raw_events_remade', conf) ...
);

bin_step = params.bin_step;
mask_func = params.mask_func;

each = { 'roi' };

look_freqs = [];
freq_labels = fcat();

for i = 1:size(ps, 1)
  shared_utils.general.progress( i, size(ps, 1) );
  
  meta_file = shared_utils.io.fload( ps{i, 1} );
  t_file = shared_utils.io.fload( ps{i, 2} );
  evt_file = shared_utils.io.fload( ps{i, 3} );
  
  start_t = t_file.t(find(~isnan(t_file.t), 1));
  stop_t = t_file.t(find(~isnan(t_file.t), 1, 'last'));
  t_series = start_t:bin_step:stop_t;
  
  evt_labs = join( fcat.from(evt_file), bfw.struct2fcat(meta_file) );  
  require_roi_labels( evt_labs );
  start_ts = bfw.event_column( evt_file, 'start_time' );
  stop_ts = bfw.event_column( evt_file, 'stop_time' );
  
  [~, ind] = bfw.make_whole_face_roi( evt_labs );
  start_ts = start_ts(ind);
  stop_ts = stop_ts(ind);
  [~, ind] = bfw.make_whole_right_nonsocial_object_roi( evt_labs );
  start_ts = start_ts(ind);
  stop_ts = stop_ts(ind);
  
  I = findall( evt_labs, each, mask_func(evt_labs, rowmask(evt_labs)) );
  for j = 1:numel(I)
    evt_ind = I{j};
    evt_start_ts = start_ts(evt_ind);
    evt_stop_ts = stop_ts(evt_ind);

    if ( params.duration_based )
      n = histcs( evt_start_ts, evt_stop_ts, t_series );
    else
      n = histc( evt_start_ts, t_series );
    end

    if ( size(look_freqs, 2) < numel(n) )
      tmp = look_freqs;
      look_freqs = nan( size(tmp, 1), numel(n) );
      look_freqs(:, 1:size(tmp, 2)) = tmp;
    end
    look_freqs(end+1, 1:numel(n)) = n;
    append1( freq_labels, evt_labs, evt_ind );
  end
end

assert_ispair( look_freqs, freq_labels );

end

function cs = histcs(starts, stops, edges)

bin_w = uniquetol( diff(edges) );
assert( numel(bin_w) == 1 );

cs = zeros( size(edges) );

e0 = edges(1:end-1);
e1 = edges(2:end);

for i = 1:numel(starts)
  start = starts(i);
  stop = stops(i);

  edge_beg = find( start >= e0 & start < e1 );
  edge_end = find( stop >= e0 & stop < e1 );
  overlap = edge_beg:edge_end;

  for j = 1:numel(overlap)
    ind = overlap(j);
    if ( j == 1 )
      off_start = start - edges(ind);
      off_stop = min( edges(ind+1), stop ) - edges(ind);
      bin_dur = off_stop - off_start;
    elseif ( j == numel(overlap) )
      bin_dur = stop - edges(ind);
    else
      bin_dur = bin_w;
    end
    assert( bin_dur >= 0 && bin_dur <= bin_w );
    cs(ind) = cs(ind) + bin_dur / bin_w;
  end
end

end

function ps = to_normalized(freqs, I)
s = cate1( rowifun(@(x) sum(x, 1), I, freqs, 'un', 0) );
ps = s ./ max( sum(s, 1) );
end

function ps = to_proportion(freqs, I)
s = cate1( rowifun(@(x) sum(x, 1), I, freqs, 'un', 0) );
% ps = s ./ max( sum(s, 1) );
den = sum( s, 1 );
zero_den = den == 0;
ps = s ./ den;
for i = 1:size(ps, 1)
  ps(i, zero_den) = 0;
end
end

function [si, durs, tf] = probability_based_state_indices(props, thresh)
tf = props >= thresh;
[si, durs] = arrayfun( @(x) shared_utils.logical.find_islands(tf(x, :)), rowmask(tf), 'un', 0 );
end

function labs = require_roi_labels(labs)
rois = { 'eyes_nf', 'face', 'right_nonsocial_object', 'right_nonsocial_object_eyes_nf_matched' };
addlab( labs, repmat({'roi'}, size(rois)), rois );
end

function [state_mean_coh, state_labs] = ...
  state_averaged_coherence(si, sdur, freq_labels, coh, coh_labels, match_I)

assert( ismatrix(coh) );
assert_ispair( si, freq_labels );
assert_ispair( sdur, freq_labels );
assert_ispair( coh, coh_labels );
assert( numel(si) == numel(match_I) );

state_mean_coh = [];
state_labs = fcat();

for i = 1:numel(si)
  match_ind = match_I{i};
  if ( isempty(match_ind) ), continue; end

  plt_coh_labs = prune( coh_labels(match_ind) );
  join( plt_coh_labs, prune(freq_labels(i)) ); 

  for j = 1:numel(si{i})
    start = si{i}(j);
    stop = start + sdur{i}(j) - 1;
    sub_coh = nanmean( coh(match_ind, start:stop), 2 );
    state_mean_coh = [ state_mean_coh; sub_coh ];
    append( state_labs, plt_coh_labs );
  end
end

end

function [pair_I, pair_labs] = pair_looking_proportions_with_coherence(...
    freq_labels, freq_I ...
  , coh_tcourse_labels, site_I)

assert( numel(freq_I) == numel(site_I) );

pair_labs = fcat();
pair_I = [];
for i = 1:numel(site_I)
  shared_utils.general.progress( i, numel(site_I) );
  mi = freq_I{i};
  l = append( fcat, freq_labels, mi );
  for j = 1:numel(site_I{i})
    si = site_I{i}(j);
    pair_I = [ pair_I; [mi, repmat(si, size(mi))] ];
    join( l, coh_tcourse_labels(si) );
    append( pair_labs, l );
  end
end

assert_ispair( pair_I, pair_labs );

end

function m = find_with_bla(l, varargin)
m = findor( l, {'spk-bla', 'lfp-bla'}, varargin{:} );
end

function ind = make_index(data, ia, ib)

assert( numel(ia) == numel(ib) );

ind = nan( numel(ia), size(data, 2) );
for i = 1:numel(ia)
  assert( numel(ia{i}) == 1 || numel(ia{i}) == 0 );
  assert( numel(ib{i}) == 1 || numel(ib{i}) == 0 );
  
  if ( isempty(ia{i}) )
    da = zeros( 1, size(data, 2) );
  else
    da = data(ia{i}, :);
  end
  
  if ( isempty(ib{i}) )
    db = zeros( 1, size(data, 2) );
  else
    db = data(ib{i}, :);
  end
  
  s = (da - db) ./ (db + da);
  s(~isfinite(s)) = 0;
  ind(i, :) = s;
end

end