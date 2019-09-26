function anova_outs = anova_classification(gaze_outs, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.post_hoc_test_func = @ranksum;
defaults.post_hoc_denominator_significant_cells = true;
defaults.post_hoc_require_main_effect_significant = true;
defaults.mask_func = @(labels) rowmask( labels );
defaults.alpha = 0.05;
params = bfw.parsestruct( defaults, varargin );

labels = gaze_outs.labels';
handle_labels( labels );

mask = get_base_mask( labels, params.mask_func );

anova_outs = anova_classify( gaze_outs.spikes, labels, mask, params );

summarize_performance( anova_outs.is_sig, anova_outs.summary_labels, params );
summarize_all_post_hoc_performance( anova_outs, params );

plot_all_post_hoc_group_ordering( anova_outs, params );

if ( params.do_save )
  save_cc_unit_info( anova_outs, params );
end

end

function plot_all_post_hoc_group_ordering(anova_outs, params)

social_ps = anova_outs.ps(:, ismember(anova_outs.factors, 'social'));
sig_cell_mask = find( social_ps < params.alpha );

plot_post_hoc_group_ordering( anova_outs, rowmask(anova_outs.labels), 'all_cells', params );
plot_post_hoc_group_ordering( anova_outs, sig_cell_mask, 'significant_cells', params );

end

function plot_post_hoc_group_ordering(anova_outs, prop_mask, prefix, params)

pl = plotlabeled.make_common();
labels = anova_outs.labels';
addsetcat( labels, 'group_ordering', anova_outs.group_ordering_ids );

[props, prop_labels] = proportions_of( labels, 'region', 'group_ordering', prop_mask );

axs = pl.bar( props, prop_labels, 'group_ordering', {}, 'region' );
title_obj = get( axs(1), 'title' );
title_str = get( title_obj, 'String' );

group_rois = anova_outs.group_ordering_rois;
roi_str = arrayfun( @(x, y) sprintf('%d: %s', x, strrep(y{1}, '_', ' ')) ...
  , 1:numel(group_rois), group_rois, 'un', 0 );
new_str = strjoin( [title_str, roi_str], ' | ' );
title_obj.String = new_str;

if ( params.do_save )
  prefix = sprintf( '%s%s', params.prefix, prefix );
  
  save_p = get_plot_p( params, 'post_hoc_group_ordering' );
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, prop_labels, 'region', prefix );
end

end

function summarize_all_post_hoc_performance(anova_outs, params)

flat_info = anova_outs.flat_post_hoc_info;
group_kinds = fieldnames( flat_info );

for i = 1:numel(group_kinds)
  subset_flat_info = anova_outs.flat_post_hoc_info.(group_kinds{i});

  post_hoc_ps = subset_flat_info.p;
  post_hoc_labels = subset_flat_info.labels';
  anova_ps = anova_outs.ps(:, ismember(anova_outs.factors, 'social'));
  anova_inds = subset_flat_info.to_post_hoc_inds;
  
  % Denominator as significant cells from anova
  is_out_of_sig = params.post_hoc_denominator_significant_cells;
  require_social_main_effect = params.post_hoc_require_main_effect_significant;
  alpha = params.alpha;
  
  [p_sig, labels, sig_inds] = posthoc_performance( post_hoc_ps, post_hoc_labels ...
    , anova_ps, anova_inds, is_out_of_sig, require_social_main_effect, alpha );
  
  unit_info = get_significant_post_hoc_unit_info( post_hoc_labels, sig_inds );
  
  if ( params.do_save )
    save_post_hoc_unit_info( unit_info, group_kinds{i}, params );
  end

  summarize_post_hoc_performance( p_sig, labels, params );
end

end

function save_post_hoc_unit_info(unit_info, subdir, params)

id_strs = keys( unit_info );

for i = 1:numel(id_strs)
  subset_unit_info = unit_info(id_strs{i});
  
  save_p = get_analysis_p( params, subdir, id_strs{i} );  
  shared_utils.io.require_dir( save_p );
  save( fullfile(save_p, 'significant_social_cell_ids.mat'), 'subset_unit_info' );
end

end

function all_unit_info = get_significant_post_hoc_unit_info(labels, sig_inds)

[comparison_I, comparison_C] = findall( labels, 'roi', sig_inds );

all_unit_info = containers.Map();

for i = 1:numel(comparison_I)
  unit_info = make_unit_info( labels, comparison_I{i} );  
  id_str = strjoin( fcat.strjoin(comparison_C(:, i)), '_' );
  all_unit_info(id_str) = unit_info;
end

end

function summarize_post_hoc_performance(p_sig, labels, params)

pl = plotlabeled.make_common();
pl.x_tick_rotation = 10;

xcats = { 'roi' };
pcats = {};
gcats = 'region';

if ( isempty(p_sig) )
  return;
end

axs = pl.bar( p_sig, labels, xcats, gcats, pcats );

if ( params.do_save )
  save_p = get_plot_p( params, 'post_hoc_performance' );
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, labels, [xcats, gcats, pcats], params.prefix );
end

end

function [p_sig, prop_labels, sig_inds] = posthoc_performance(ps, labels, anova_ps, anova_inds ...
 , is_out_of_sig, require_social_main_effect, alpha)

assert( isvector(anova_ps), 'Anova p values were not vector.' );

unit_I = findall( labels, {'region'} );

p_sig = [];
prop_labels = fcat();
sig_inds = {};

for i = 1:numel(unit_I)
  roi_I = findall( labels, 'roi', unit_I{i} );
  
  for j = 1:numel(roi_I)
    roi_ind = roi_I{j};
    
    subset_anova_ps = anova_ps(anova_inds(roi_ind));

    if ( require_social_main_effect )
      anova_crit = subset_anova_ps < alpha;
    else
      anova_crit = true( size(subset_anova_ps) );
    end

    post_hoc_crit = ps(roi_ind) < alpha;
    total_crit = post_hoc_crit & anova_crit;
    
    sig_inds{end+1, 1} = roi_ind(total_crit);
    
    num_sig = nnz( total_crit );
    
    if ( is_out_of_sig )      
      denom = nnz( anova_crit );
    else
      denom = numel( roi_ind );
    end

    p_sig(end+1, 1) = num_sig / denom;
    append1( prop_labels, labels, roi_ind );
  end
end

sig_inds = vertcat( sig_inds{:} );

end

function summarize_performance(is_sig, labels, params)

assert_ispair( is_sig, labels );

pl = plotlabeled.make_common();
pl.summary_func = @mean;
pl.error_func = @(varargin) nan;
pl.y_lims = [0, 0.4];

xcats = {};
gcats = { 'region' };
pcats = { 'main_effect' };

axs = pl.bar( double(is_sig), labels, xcats, gcats, pcats );

if ( params.do_save )
  save_p = get_plot_p( params, 'summarized_performance' );
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, labels, pcats, params.prefix );
end

end

function outs = anova_classify(spikes, labels, mask, params)

anova_each = { 'unit_uuid', 'session', 'region' };
anova_factors = { 'roi' };

[anova_labs, anova_I] = keepeach( labels', anova_each, mask );
social_group = make_social_group( labels, mask );

ps = cell( size(anova_I) );
stat_tables = cell( size(ps) );
all_post_hoc_info = cell( size(ps) );
group_ordering_ids = cell( size(ps) );
all_roi_combs = cell( size(ps) );

post_hoc_func = params.post_hoc_test_func;

parfor i = 1:numel(anova_I)
  anova_ind = anova_I{i}; 
  
  subset_spikes = spikes(anova_ind);
  subset_social_group = social_group(anova_ind);
  
  groups = cellfun( @(x) categorical(labels, x, anova_ind), anova_factors, 'un', 0 );
  groups{end+1} = subset_social_group;
  
  nesting = zeros( numel(anova_factors)+1 );
  roi_ind = find( strcmp(anova_factors, 'roi') );
  % Nest rois in social
  nesting(roi_ind, numel(groups)) = 1;
  
  [p, tbl, stats] = anovan( subset_spikes, groups ...
    , 'nested', nesting ...
    , 'varnames', [anova_factors, {'social'}] ...
    , 'display', 'off' ...
  );

  ps{i} = p(:)';
  stat_tables{i} = stats;
  
  social_rois = sort( combs(labels, 'roi', anova_ind(subset_social_group == 'social')) );
  nonsocial_rois = sort( combs(labels, 'roi', anova_ind(subset_social_group == 'nonsocial')) );
  [roi_I, roi_combs] = findall( labels, 'roi', anova_ind );
  
  [all_rois, sort_ind] = sort( roi_combs );
  roi_I = roi_I(sort_ind);
  
  post_hoc_groups = { social_rois, nonsocial_rois, all_rois };
  post_hoc_group_names = { 'social', 'nonsocial', 'all' };
  post_hoc_info = struct();
  
  for j = 1:numel(post_hoc_groups)
    [post_hoc_p, roi_strs] = post_hoc_comparisons( spikes, labels, post_hoc_groups{j}, anova_ind, post_hoc_func );
    post_hoc_info.(post_hoc_group_names{j}).p = post_hoc_p;
    post_hoc_info.(post_hoc_group_names{j}).rois = roi_strs;
  end
  
  group_means = bfw.row_nanmean( spikes, roi_I );
  [~, group_ordering] = sort( group_means );
  
  group_ordering_ids{i} = strjoin( arrayfun(@num2str, group_ordering, 'un', 0), ',' );
  all_roi_combs{i} = roi_combs;
  
  all_post_hoc_info{i} = post_hoc_info;
end

ps = vertcat( ps{:} );
stat_tables = vertcat( stat_tables{:} );
group_ordering_rois = conditional( @() isempty(all_roi_combs), @() {}, all_roi_combs{1} );
all_post_hoc_info = vertcat( all_post_hoc_info{:} );

post_hoc_info = gather_post_hoc_info( all_post_hoc_info );

outs = struct();
outs.ps = ps;
outs.factors = [ anova_factors, {'social'} ];
outs.stat_tables = stat_tables;
outs.labels = anova_labs;
outs.post_hoc_info = all_post_hoc_info;
outs.group_ordering_ids = group_ordering_ids;
outs.group_ordering_rois = group_ordering_rois;

[outs.is_sig, outs.summary_labels] = make_summary_info( ps, anova_labs', params.alpha );
outs.flat_post_hoc_info = make_flat_post_hoc_info( post_hoc_info, anova_labs );

end

function post_hoc_info = gather_post_hoc_info(all_post_hoc_info)

post_hoc_info = struct();
post_hoc_groups = fieldnames( all_post_hoc_info );

for i = 1:numel(post_hoc_groups)
  combined = [ all_post_hoc_info.(post_hoc_groups{i}) ];
  fs = fieldnames( combined );
  values = struct2cell( combined );
  
  for j = 1:numel(fs)
    post_hoc_info.(post_hoc_groups{i}).(fs{j}) = values(j, :)';
  end
end

end

function flat_post_hoc_info = make_flat_post_hoc_info(all_post_hoc_info, anova_labs)

post_hoc_groups = fieldnames( all_post_hoc_info );
flat_post_hoc_info = struct();

for i = 1:numel(post_hoc_groups)
  grp = post_hoc_groups{i};
  [flat_ps, flat_labels, to_post_hoc_inds] = ...
    flatten_post_hoc( anova_labs, all_post_hoc_info.(grp).p, all_post_hoc_info.(grp).rois );
  flat_post_hoc_info.(grp).p = flat_ps;
  flat_post_hoc_info.(grp).labels = flat_labels;
  flat_post_hoc_info.(grp).to_post_hoc_inds = to_post_hoc_inds;
end

end

function [post_hoc_p, roi_strs] = post_hoc_comparisons(spikes, labels, rois, mask, post_hoc_func)

pair_inds = roi_pair_inds( numel(rois) );
post_hoc_p = zeros( size(pair_inds, 1), 1 );
roi_strs = cell( size(post_hoc_p) );

for j = 1:size(pair_inds, 1)
  roi_a = rois{pair_inds(j, 1)};
  roi_b = rois{pair_inds(j, 2)};
  roi_strs{j} = sprintf( '%s vs %s', roi_a, roi_b );

  ind_a = find( labels, roi_a, mask );
  ind_b = find( labels, roi_b, mask );

  post_hoc_p(j) = post_hoc_func( spikes(ind_a), spikes(ind_b) );
end

end

function [ps, labels, inds] = flatten_post_hoc(anova_labs, post_hoc_ps, post_hoc_rois)

assert_ispair( post_hoc_ps, anova_labs );
assert_ispair( post_hoc_rois, anova_labs );

labels = fcat.like( anova_labs );
ps = vertcat( post_hoc_ps{:} );
inds = [];

for i = 1:numel(post_hoc_rois)
  roi_set = post_hoc_rois{i};
  
  for j = 1:numel(roi_set)
    append( labels, anova_labs, i );
    setcat( labels, 'roi', roi_set{j}, rows(labels) );
    inds(end+1, 1) = i;
  end
end

prune( labels );

end

function inds = roi_pair_inds(num_rois)

[ii, ij] = ndgrid( (1:num_rois)', (1:num_rois)' );
inds = unique( sort([ii(:), ij(:)], 2), 'rows' );
inds(inds(:, 1) == inds(:, 2), :) = [];

end

function [is_sig, summary_labels] = make_summary_info(ps, labels, alpha)

is_sig = ps < alpha;

roi_sig = is_sig(:, 1);
social_sig = is_sig(:, 2);

summary_labels = fcat();

addcat( labels, 'main_effect' );
setcat( labels, 'main_effect', 'roi' );
append( summary_labels, labels );
setcat( labels, 'main_effect', 'social' );
append( summary_labels, labels );

is_sig = [ roi_sig; social_sig ];

end

function social_group = make_social_group(labels, mask)

social_ind = findor( labels, social_rois(), mask );  
nonsocial_ind = findor( labels, nonsocial_rois(), mask );
social_group = categorical();
social_group(rowmask(labels), 1) = '<undefined>';
social_group(social_ind) = 'social';
social_group(nonsocial_ind) = 'nonsocial';

end

function rois = social_rois()

rois = { 'eyes_nf', 'face', 'face_non_eyes' };

end

function rois = nonsocial_rois()

rois = { 'left_nonsocial_object', 'right_nonsocial_object', 'nonsocial_object' ...
  , 'left_nonsocial_object_eyes_nf_matched', 'right_nonsocial_object_eyes_nf_matched' ...
};

end

function labels = handle_labels(labels)

bfw.unify_single_region_labels( labels );

end

function mask = get_base_mask(labels, mask_func)

mask = fcat.mask( labels, mask_func(labels) ...
  , @findnone, bfw.nan_unit_uuid() ...
  , @find, 'm1' ...
  , @find, 'exclusive_event' ...
);

end

function save_p = get_plot_p(params, varargin)

save_p = get_save_p( params, 'plots', varargin{:} );

end

function save_p = get_analysis_p(params, varargin)

save_p = get_save_p( params, 'analyses', varargin{:} );

end

function save_p = get_save_p(params, subdir, varargin)

save_p = fullfile( bfw.dataroot(params.config), subdir, 'cell_type_classification' ...
  , dsp3.datedir, params.base_subdir, varargin{:} );

end

function unit_info = make_unit_info(labels, mask)

labels = copy( labels );
replace( labels, 'acc', 'accg' );

unit_combs = combs( labels, {'unit_uuid', 'region', 'session'}, mask )';
unit_id_numbers = fcat.parse( unit_combs(:, 1), 'unit_uuid__' );

unit_info = arrayfun( @(u, r, s) struct('unit', {u}, 'region', {r}, 'session', {s}) ...
  , unit_id_numbers, unit_combs(:, 2), unit_combs(:, 3) );

end

function save_cc_unit_info(anova_outs, params)

social_ind = find( anova_outs.summary_labels, 'social' );
is_sig_social = anova_outs.is_sig(social_ind);
social_labels = prune( anova_outs.summary_labels(social_ind) );

sig_social_cell_info = make_unit_info( social_labels, find(is_sig_social) );

save_p = get_analysis_p( params );
shared_utils.io.require_dir( save_p );

save( fullfile(save_p, 'significant_social_cell_ids.mat'), 'sig_social_cell_info' );

end