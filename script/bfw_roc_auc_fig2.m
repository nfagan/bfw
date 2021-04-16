%%  Load data

all_files = shared_utils.io.findmat( bfw.gid('raw_events_remade') );
all_files = shared_utils.io.filenames( all_files, true );
sessions = cellfun( @(x) x(1:8), all_files, 'un', 0 );
unique_sessions = unique( sessions );
num_session_bins = 5;
binned_sessions = shared_utils.vector.distribute( 1:numel(unique_sessions), num_session_bins );
binned_sessions = cellfun( @(x) unique_sessions(x), binned_sessions, 'un', 0 );

session_auc = {};

for session_index = 1:numel(binned_sessions)
  
shared_utils.general.progress( session_index, numel(binned_sessions) );

seshs = binned_sessions{session_index};
sesh_ind = ismember( sessions, seshs );

select_files = all_files(sesh_ind);

% select_files = [
%   {'01042019'}
%   {'01092019'}
%   {'01112019'}
%   {'01132019'}
%   {'01152019'}
%   {'02042018'}
%   {'09292018'}
%   {'10092018'}
% ];

bin_size = 1e-2;
step_size = 1e-2; % 10ms

res = bfw_make_psth_for_fig1( ...
    'is_parallel', true ...
  , 'window_size', bin_size ...
  , 'step_size', step_size ...
  , 'look_back', -0.5 ...
  , 'look_ahead', 0.5 ...
  , 'files_containing', select_files(:)' ...
  , 'include_rasters', false ...
);

%%  Add whole face roi

gaze_counts = add_whole_face_roi( res.gaze_counts );

%%  Remove nonsocial object events prior to the actual introduction of the object.

base_mask = get_base_mask( gaze_counts.labels );

%%  Auc for each unit, test significance with permutation test

labels = gaze_counts.labels';
spikes = gaze_counts.spikes;

smooth_each = true;
if ( smooth_each )
  for i = 1:size(spikes, 1)
    spikes(i, :) = movsum( spikes(i, :), 10 );
  end
end

perm_iters = 1e2;
n_consecutive = 5;

units_each = { 'unit_uuid', 'unit_index', 'region', 'session' };
roi_pairs = { {'whole_face', 'nonsocial_object'} };

mask = fcat.mask( labels, base_mask );
[unit_labels, unit_I] = keepeach( labels', units_each, mask );

auc_labels = cell( numel(unit_I), 1 );
auc = cell( size(auc_labels) );
auc_sig_info = cell( size(auc_labels) );

parfor i = 1:numel(unit_I)
  shared_utils.general.progress( i, numel(unit_I) );
  
  tmp_auc = [];
  tmp_sig_info = {};
  tmp_auc_labels = fcat();
  
  for j = 1:numel(roi_pairs)
    roi_a = roi_pairs{j}{1};
    roi_b = roi_pairs{j}{2};
    ind_a = find( labels, roi_a, unit_I{i} );
    ind_b = find( labels, roi_b, unit_I{i} );
    
    [real_auc, sig_info] = auc_for_pair( spikes, ind_a, ind_b, perm_iters, n_consecutive );
    labs = setcat( unit_labels(i), 'roi', sprintf('%s_%s', roi_a, roi_b) );
    
    append( tmp_auc_labels, labs );
    tmp_auc = [ tmp_auc; real_auc ];
    tmp_sig_info{end+1, 1} = sig_info;
  end
  
  auc_labels{i} = tmp_auc_labels;
  auc{i} = tmp_auc;
  auc_sig_info{i} = vertcat( tmp_sig_info{:} );
end

auc = vertcat( auc{:} );
auc_labels = vertcat( fcat, auc_labels{:} );
auc_sig_info = vertcat( auc_sig_info{:} );

session_auc{session_index} = struct( 'auc', auc, 'auc_labels', auc_labels, 'auc_sig_info', auc_sig_info );

end

%%  concatenate

auc_info = vertcat( session_auc{:} );
auc = cat_expanded( 1, {auc_info.auc} );
auc_labels = cat_expanded( 1, {fcat, auc_info.auc_labels} );
auc_sig_info = cat_expanded( 1, {auc_info.auc_sig_info} );

%%  Plot auc heat maps

plt_auc = auc;
plt_auc_labels = auc_labels';
plt_auc_sig_info = auc_sig_info;
t = gaze_counts.t;

assert_ispair( plt_auc, plt_auc_labels );
assert_ispair( plt_auc_sig_info, plt_auc_labels );

is_sig = [ plt_auc_sig_info.sig_neg ] | [ plt_auc_sig_info.sig_pos ];

figs_each = { 'roi' };

plt_mask = get_base_mask( plt_auc_labels, false );
fig_I = findall( plt_auc_labels, figs_each, plt_mask );
f = figure(1);

c_lims = [0.3, 0.7];

conf = bfw.config.load();
do_save = true;

for i = 1:numel(fig_I)
  clf();
  
  [p_I, p_C] = findall( plt_auc_labels, [{'region'}, figs_each], fig_I{i} );
  ss = plotlabeled.get_subplot_shape( numel(p_I) );
  
  for j = 1:numel(p_I)
    ax = subplot( ss(1), ss(2), j );
    cla( ax );
    hold( ax, 'on' );
    
    p_ind = p_I{j};
    sig_p_ind = p_ind(is_sig(p_ind));
    [sort_ind, first_sig] = sort_sig( plt_auc_sig_info(sig_p_ind) );
    sig_p_ind = sig_p_ind(sort_ind);
    
    sub_auc = plt_auc(sig_p_ind, :);
    
    h_im = imagesc( ax, t, 1:size(sub_auc, 1), sub_auc );
    
    first_xs = gaze_counts.t(first_sig);
    first_ys = 1:numel(first_sig);
    plot_white_lines( ax, first_xs, first_ys );
    
    num_sig = numel( sig_p_ind );
    num_tot = numel( p_ind );
    
    pc_str = strrep( strjoin(p_C(:, j), ' | '), '_', ' ' );
    title_str = sprintf( '%s (%d of %d [%0.2f%%])', pc_str ...
      , num_sig, num_tot, num_sig/num_tot*100 );
    title( ax, title_str );
    
    shared_utils.plot.set_clims( ax, c_lims );
    shared_utils.plot.set_xlims( ax, [min(t), max(t)] );
    shared_utils.plot.set_ylims( ax, [1, numel(sig_p_ind)] );
    
    colormap( 'jet' );
    colorbar;
  end
  
  if ( do_save )
    save_p = fullfile( bfw.dataroot(conf), 'plots/auc', dsp3.datedir, 'heatmaps' );
    shared_utils.plot.fullscreen( gcf );
    dsp3.req_savefig( gcf, save_p, plt_auc_labels, [{'region'}, figs_each] );
  end
end

%%  Average AUC traces

plt_auc = auc;
plt_auc(plt_auc < 0.5) = (0.5 - plt_auc(plt_auc < 0.5)) + 0.5;

plt_auc_labels = auc_labels';
plt_auc_sig_info = auc_sig_info;
t = gaze_counts.t;
is_sig = [ plt_auc_sig_info.sig_neg ] | [ plt_auc_sig_info.sig_pos ];

plt_mask = get_base_mask( plt_auc_labels, false );
plt_mask = intersect( plt_mask, find(is_sig) );

pl = plotlabeled.make_common();
pl.x = t;
axs = pl.lines( plt_auc(plt_mask, :), plt_auc_labels(plt_mask), 'roi', 'region' );

do_save = true;
conf = bfw.config.load();

if ( do_save )
  save_p = fullfile( bfw.dataroot(conf), 'plots/auc', dsp3.datedir, 'avg_traces' );
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, plt_auc_labels, 'region' );
end

%%

function plot_white_lines(ax, xs, ys)

for i = 1:numel(xs)-1
  x0 = xs(i);
  x1 = xs(i+1);
  y0 = ys(i);
  y1 = ys(i+1);
  h = plot( ax, [x0; x1], [y0; y1] );
  set( h, 'color', ones(1, 3) );
  set( h, 'linewidth', 4 );
end

end

function [real_auc, sig_info] = auc_for_pair(spikes, ind_a, ind_b, perm_iters, n_consecutive)

assert( perm_iters == 100 );  % expect p < 0.01

if ( isempty(ind_a) || isempty(ind_b) )
  real_auc = nan( 1, size(spikes, 2) );
  null_aucs = nan( perm_iters, size(spikes, 2) );
  
else
  real_auc = auc_over_time( spikes, ind_a, ind_b );

  null_aucs = cell( perm_iters, 1 );
  for k = 1:perm_iters
    [ia, ib] = shuffle2( ind_a, ind_b );
    null_aucs{k} = auc_over_time( spikes, ia, ib );
  end
  null_aucs = vertcat( null_aucs{:} );
  null_aucs = sort( null_aucs );
end

sig_le = real_auc < null_aucs(1, :);
sig_gt = real_auc > null_aucs(end, :);
[isles_le, durs_le] = find_consecutive( sig_le, n_consecutive );
[isles_gt, durs_gt] = find_consecutive( sig_gt, n_consecutive );

sig_info = struct();
sig_info.sig_neg = ~isempty( isles_le );
sig_info.sig_pos = ~isempty( isles_gt );
sig_info.first_neg = min( isles_le );
sig_info.first_pos = min( isles_gt );

end

function aucs = auc_over_time(spikes, ind_a, ind_b)

aucs = nan( 1, size(spikes, 2) );

for i = 1:size(spikes, 2)
  spks_a = spikes(ind_a, i);
  spks_b = spikes(ind_b, i);
  auc = score_auc( spks_a, spks_b );
  aucs(i) = auc;
end

end

function auc = score_auc(a, b)

t = false( numel(a) + numel(b), 1 );
t(1:numel(a)) = true;
y = [ a; b ];
auc = scoreAUC( t, y );

end

function [auc, tpr, fpr] = roc_auc(a, b)

t = false( numel(a) + numel(b), 1 );
t(1:numel(a)) = true;

y = [ a; b ];
[tpr, fpr] = roc( t(:)', y(:)' );

if ( abs(max(fpr)-1) >= eps )
  fpr(end+1) = 1;
  tpr(end+1) = 1;
end

auc = trapz( fpr, tpr );

end

function [i, d] = find_consecutive(v, ct)

[i, d] = shared_utils.logical.find_islands( v );
thresh = d >= ct;
i = i(thresh);
d = d(thresh);

end

function [ic, id] = shuffle2(ia, ib)

i = [ia; ib];
i = i(randperm(numel(i)));
ic = i(1:numel(ia));
id = i(numel(ia)+1:end);
assert( numel(ic) == numel(ia) && numel(id) == numel(ib) );

end

function base_mask = get_base_mask(labels, only_remove_obj)

if ( nargin < 2 )
  only_remove_obj = true;
end

if ( only_remove_obj )
  sesh_mask = find( labels, 'nonsocial_object' );
else
  sesh_mask = rowmask( labels );
end

base_mask = bfw.find_sessions_before_nonsocial_object_was_added( labels, sesh_mask );
base_mask = setdiff( rowmask(labels), base_mask );

end

function gaze_counts = add_whole_face_roi(gaze_counts)

gaze_counts.labels = gaze_counts.labels';
replace( gaze_counts.labels, 'nonsocial_object_eyes_nf_matched', 'nonsocial_object' );

[~, transform_ind] = bfw.make_whole_face_roi( gaze_counts.labels );
gaze_counts.spikes = gaze_counts.spikes(transform_ind, :);
gaze_counts.events = gaze_counts.events(transform_ind, :);

end

function [ind, vs] = sort_sig(sig_info)

vs = zeros( numel(sig_info), 1 );
is_neg = false( size(vs) );

for i = 1:numel(sig_info)
  [~, is_neg(i), vs(i)] = sorting_index_value( sig_info(i) );
end

src_ind = 1:numel(sig_info);

src_neg = src_ind(is_neg);
[neg_vs, neg_ind] = sort( vs(is_neg), 'desc' );
neg_ind = src_neg(neg_ind);

src_pos = src_ind(~is_neg);
[pos_vs, pos_ind] = sort( vs(~is_neg) );
pos_ind = src_pos(pos_ind);

ind = [ neg_ind(:); pos_ind(:) ];
vs = [ neg_vs(:); pos_vs(:) ];

end

function [is_sig, is_neg, s] = sorting_index_value(sig_info)

is_sig = false;
is_neg = false;
s = 0;

if ( sig_info.sig_pos && ~sig_info.sig_neg )
  is_sig = true;
  s = sig_info.first_pos;
end
if ( ~sig_info.sig_pos && sig_info.sig_neg )
  is_sig = true;
  s = sig_info.first_neg;
  is_neg = true;
end
if ( sig_info.sig_pos && sig_info.sig_neg )
  is_sig = true;
  if ( sig_info.first_pos < sig_info.first_neg )
    s = sig_info.first_pos;
  else
    s = sig_info.first_neg;
    is_neg = true;
  end
end

end