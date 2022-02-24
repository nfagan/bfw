%%

inputs = { 'aligned_raw_samples/position', 'meta', 'rois' };

args = struct();

[~, runner] = bfw.get_params_and_loop_runner( inputs, '', bfw.get_common_make_defaults(), {args} );
runner.convert_to_non_saving_with_output();
runner.is_parallel = true;

res = runner.run( @find_saccades );
sacc_outs = shared_utils.pipeline.extract_outputs_from_results( res );
sacc_outs = shared_utils.struct.soa( sacc_outs );

%%

bfw.add_monk_labels( sacc_outs.labels );
[I, C] = findall( sacc_outs.labels, 'looks_by' );
for i = 1:numel(I)
  [m_I, m_C] = findall( sacc_outs.labels, sprintf('id_%s', C{i}), I{i} );
  monk_labs = strrep( m_C, sprintf('%s_', C{i}), 'sacc-' );
  for j = 1:numel(m_I)
    addsetcat( sacc_outs.labels, 'sacc_by', monk_labs{j}, m_I{j} );
  end
end
prune( sacc_outs.labels );

%%

rois = sacc_outs.rois(1, :);
is_obj = ismember( rois, {'left_nonsocial_object', 'left_nonsocial_object_eyes_nf_matched' ...
  , 'right_nonsocial_object', 'right_nonsocial_object_eyes_nf_matched'} );
ib_obj = any( sacc_outs.in_bounds(:, is_obj), 2 );
ib_eyes = sacc_outs.in_bounds(:, ismember(rois, 'eyes_nf'));
ib_face = sacc_outs.in_bounds(:, ismember(rois, 'face'));
ib_face = ib_face & ~ib_eyes;

sacc_labs = addcat( sacc_outs.labels', 'roi' );
rois = { 'eyes_nf', 'face', 'nonsocial_object' };
ibs = { ib_eyes, ib_face, ib_obj };
for i = 1:numel(rois)
  setcat( sacc_labs, 'roi', rois{i}, find(ibs{i}) );
end

%%

X = sacc_outs.sacc_info(:, 4);  % amp
Y = sacc_outs.sacc_info(:, 3);  % peak vel
plt_labs = sacc_labs';

max_vel = 450;

mask_func = @(l) pipe( rowmask(l) ...
  , @(m) intersect(m, find(~isnan(X) & ~isnan(Y))) ...
  , @(m) intersect(m, find(Y < max_vel)) ...
  , @(m) find(l, rois, m) ...
  , @(m) find(l, 'free_viewing', m) ...
  , @(m) find(l, 'm1', m) ...
);

mask = mask_func( plt_labs );

plt_X = X(mask);
plt_Y = Y(mask);
plt_labs = prune( plt_labs(mask) );
pl = plotlabeled.make_common();
[axs, ids] = pl.scatter( plt_X, plt_Y, plt_labs, 'roi', {} );
xlabel( axs(1), 'Amplitude (deg)' );
ylabel( axs(1), 'Peak velocity (deg/s)' );
plotlabeled.scatter_addcorr( ids, plt_X, plt_Y );

%%

bin_labs = sacc_labs';
mask = mask_func( bin_labs );
bin_X = X(mask);
bin_Y = Y(mask);
roi_names = categorical( bin_labs, 'roi', mask );
sub_labs = prune( bin_labs(mask) );

bin_size_x = 5;
bin_size_y = 50;

nbx = ceil( max(bin_X)/bin_size_x ) * bin_size_x;
nby = ceil( max(bin_Y)/bin_size_y ) * bin_size_y;
bx = 0:bin_size_x:nbx;
by = 0:bin_size_y:nby;

clusters = kmeans( [bin_X, bin_Y], 3, 'replicates', 5 );
[un_clusters, ~, ic] = unique( clusters );
un_I = groupi( ic );

cluster_labs = fcat();
cluster_counts = [];

ratio_labs = fcat();
ratios = [];

for i = 1:numel(un_I)
  ui = un_I{i};
  rois_this_cluster = roi_names(ui);
  labs = fcat.create( 'roi', cellstr(rois_this_cluster), 'cluster', sprintf('cluster-%d', un_clusters(i)) );
  [roi_counts, count_labs] = counts_of( labs, {}, 'roi' );
  append( cluster_labs, count_labs );
  cluster_counts = [ cluster_counts; roi_counts ];
  
  [roi_labs, roi_I] = keepeach( sub_labs', 'roi', ui );
  stat_ratio = cellfun( @(x) bin_Y(x) ./ bin_X(x), roi_I, 'un', 0 );
  addsetcat( roi_labs, 'cluster', sprintf('cluster-%d', un_clusters(i)) );
  for j = 1:numel(roi_I)
    append1( ratio_labs, roi_labs, j, numel(stat_ratio{j}) );
    ratios = [ ratios; stat_ratio{j} ];
  end
end

anova_outs = dsp3.anovan2( ratios, ratio_labs, {'roi'}, {'cluster'} );
dsp3.save_anova_outputs( anova_outs, 'C:\Users\nick\Desktop', 'roi' );

%%

% stats = dsp3.chi2_gof( cluster_counts, cluster_labs, {'cluster'}, 'roi' );

%%

comp_each = {};
comp_mask = mask_func( sacc_labs );
[comp_labs, comp_I] = keepeach_or_one( sacc_labs', comp_each, comp_mask );
iter = 1e2;

perm_labs = fcat();
perm_ps = [];
for i = 1:numel(comp_I)
  shared_utils.general.progress( i, numel(comp_I) );
  
  ci = comp_I{i};
  [roi_I, roi_C] = findall( sacc_labs, 'roi', ci );
  pairi = bfw.pair_combination_indices( numel(roi_I) );
  for j = 1:size(pairi, 1)
    pair = pairi(j, :);
    a = roi_C(:, pair(1));
    b = roi_C(:, pair(2));
    ai = roi_I{pair(1)};
    bi = roi_I{pair(2)};
    
    fit_mdl = @(i) fitlm(X(i), Y(i));
    mdl_slope_diff = @(ma, mb) ma.Coefficients.Estimate(2) - mb.Coefficients.Estimate(2);
    
    mdla = fit_mdl( ai );
    mdlb = fit_mdl( bi );
    real_diff = abs( mdl_slope_diff(mdla, mdlb) );
    null_gt = false( iter, 1 );
    
    for k = 1:iter
      m = [ ai; bi ];
      m = m(randperm(numel(m)));
      ai_shuff = m(1:numel(ai));
      bi_shuff = m(numel(ai)+1:end);
      null_diff = abs( mdl_slope_diff(fit_mdl(ai_shuff), fit_mdl(bi_shuff)) );
      null_gt(k) = null_diff > real_diff;
    end
    
    p = sum( null_gt ) / iter;
    labs = append1( fcat, comp_labs, i );
    setcat( labs, 'roi', sprintf('%s_%s', strjoin(a), strjoin(b)) );
    append( perm_labs, labs );
    perm_ps = [ perm_ps; p ];
  end
end

%%

is_sig = perm_ps < 0.05 / 3;
sig_lab = repmat( {'sig-true'}, numel(is_sig), 1 );
sig_lab(~is_sig) = {'sig-false'};
tbl = array2table( perm_ps(:), 'rownames', fcat.strjoin([perm_labs(:, {'roi', 'sacc_by'}), sig_lab]', ' | ') );

%%

function out = find_saccades(files, varargin)

defaults = struct();
defaults.vel_thresh = 50; % deg/s
defaults.dur_thresh = 50; % min num samples
defaults.sr = 1e3;  % sample rate
defaults.smooth_func = @(data) smoothdata( data, 'smoothingfactor', 0.05 );
defaults.rois = { 'eyes_nf', 'face' ...
  'right_nonsocial_object', 'right_nonsocial_object_eyes_nf_matched' ...
  , 'left_nonsocial_object', 'left_nonsocial_object_eyes_nf_matched' };
params = shared_utils.general.parsestruct( defaults, varargin );

pos = files('position');
meta = files('meta');
rois = files('rois');

ms = intersect( fieldnames(pos), {'m1', 'm2'} );
roi_names = params.rois;

ibs = cell( numel(ms), 1 );
labels = cell( size(ibs) );
sacc_info = cell( size(ibs) );

for i = 1:numel(ms)
  p = pos.(ms{i});
  rects = rois.(ms{i}).rects;
  
  x = p(1, :);
  y = p(2, :);
  
  dx = bfw.px2deg( x );
  dy = bfw.px2deg( y );
  saccs = hwwa.find_saccades(...
    dx, dy, params.sr, params.vel_thresh, params.dur_thresh, params.smooth_func );
  saccs = saccs{1};
  
  end_px = cat_expanded( 1, arrayfun(@(ei) [x(ei), y(ei)], saccs(:, 2), 'un', 0) );
  src_d = cat_expanded( 1, arrayfun(@(ei) [dx(ei), dy(ei)], saccs(:, 1), 'un', 0) );
  end_d = cat_expanded( 1, arrayfun(@(ei) [dx(ei), dy(ei)], saccs(:, 2), 'un', 0) );
  sacc_amp = vecnorm( end_d - src_d, 2, 2 );
  
  ib = false( rows(saccs), numel(roi_names) );
  
  for j = 1:numel(roi_names)
    rect = rects(roi_names{j});
    ib(:, j) = shared_utils.rect.inside( rect, end_px(:, 1), end_px(:, 2) );
  end
  
  labs = bfw.struct2fcat( meta );
  addsetcat( labs, 'looks_by', ms{i} );
  repmat( labs, rows(ib) );
  
  ibs{i} = ib;
  sacc_info{i} = [saccs, sacc_amp];
  labels{i} = labs;
end

ibs = vertcat( ibs{:} );
sacc_info = vertcat( sacc_info{:} );
labels = vertcat( fcat, labels{:} );

assert_ispair( ibs, labels );
assert_ispair( sacc_info, labels );

out = struct();
out.rois = roi_names;
out.in_bounds = ibs;
out.sacc_info = sacc_info;
out.labels = labels;

end