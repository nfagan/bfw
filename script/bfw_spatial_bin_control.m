conf = bfw.config.load();

use_whole_face = true;
sorted_events = load_events( conf, use_whole_face );

%%

spike_data = load_spike_data( conf );
sample_files = load_sample_files( conf );
roi_files = load_roi_files( conf );

%%

m1_positions = sample_files.position(:, 2);
m1_ts = sample_files.time(:, 2);

%%  

start_ts = bfw.event_column( sorted_events, 'start_time' );
stop_ts = bfw.event_column( sorted_events, 'stop_time' );

evt_labs = sorted_events.labels';

%% find events preceding looks to a target roi

[event_inds, event_ind_labels] = find_preceding_event_indices( start_ts, evt_labs );

%%
% find events except those belonging to target roi(s), and except those for
% which a target roi event occurs within some time of the event.

[event_inds, event_ind_labels] = find_events_excluding_target_rois( start_ts, evt_labs );

%%  use all events identified by a mask

[event_inds, event_ind_labels] = find_most_events( start_ts, evt_labs );

%% assign events to a spatial bin based on the position of the event

event_positions = ...
    preceding_event_positions( start_ts, stop_ts, m1_ts, m1_positions ...
  , sorted_events.labels, sample_files.labels, event_inds );

run_I = findall( event_ind_labels, 'unified_filename' );
[grid_indices, pos_degrees] = ...
  roi_centered_grid_indices( event_positions, event_ind_labels, roi_files, run_I );

[~, grid_cat] = apply_grid_index_labels( event_ind_labels, grid_indices );

%%  make psth

psth_epoch = 'pre';

switch ( psth_epoch )
  case 'full'
    psth_params = struct( 't_win', [-0.5, 0.5], 'bin_width', 0.05 );
    epoch_prefix = 'pre_post_fixation_activity';
  case 'pre'
    psth_params = struct( 't_win', [-0.5, 0], 'bin_width', 0.05 );
    epoch_prefix = 'pre_fixation_activity';
  case 'post'
    psth_params = struct( 't_win', [0, 0.5], 'bin_width', 0.05 );
    epoch_prefix = 'post_fixation_activity';
  otherwise
    error( 'Unrecognized psth epoch "%s".', psth_epoch );
end

cell_subset = 1:numel(spike_data.spike_times);  % all cells.

[psth, psth_labels, bin_t, psth_event_inds, psth_pos_inds] = ...
  make_psth( spike_data.spike_times(cell_subset), spike_data.labels(cell_subset) ...
  , start_ts, event_inds, event_ind_labels, psth_params );

t_mean_psth = nanmean( psth, 2 );
psth_event_pos = pos_degrees(psth_pos_inds, :);

%%  or load post psth

[psth, psth_labels, bin_t, psth_event_inds, psth_pos_inds, psth_event_pos] = ...
  load_post_psth( conf );
t_mean_psth = nanmean( psth, 2 );

%%

x_deg_inds = degree_bin_indices( psth_event_pos(:, 1), -20, 20, 8 );
y_deg_inds = degree_bin_indices( psth_event_pos(:, 2), -20, 20, 8 );

%%  linear model for degree tuning

use_binned_pos = false;
use_mean_binned_pos = true;

use_mean_psth = t_mean_psth;
use_psth_labels = psth_labels';

if ( use_binned_pos )
  event_pos = [x_deg_inds(:), y_deg_inds(:)];
  
  if ( use_mean_binned_pos )
    [use_mean_psth, use_psth_labels, event_pos] = ...
      collapse_degree_bins( use_mean_psth, use_psth_labels', event_pos );
  end
else
  event_pos = psth_event_pos;
end

%%
rng_state = load_rng_state( conf );

[mdls, mdl_ps, mdl_perm_ps, mdl_labels] = degree_linear_model( use_mean_psth, event_pos, use_psth_labels ...
  , 'permute', true ...
  , 'iters', 1e2 ...
  , 'rng_state', rng_state ...
);

%%  pie for model perf

% use_mdl_ps = model_res.mdl_ps;
% mdl_labels = model_res.mdl_labels';

use_mdl_ps = mdl_perm_ps;
% use_mdl_ps = mdl_ps;
plot_linear_model_p_sig( use_mdl_ps, mdl_labels' ...
  , 'do_save', true ...
  , 'prefix', epoch_prefix ...
);

%%  scatter for model perf

for i = 1:numel(mdls)
  shared_utils.general.progress( i, numel(mdls) );
  
  plot_linear_model_scatters( mdls(i), mdl_labels(i) ...
    , 'do_save', true ...
    , 'prefix', epoch_prefix ...
  );
end

%%  anova for grid index

exclude_face_roi = true;

if ( exclude_face_roi )
  plt_mask_func = @(l, m) fcat.mask(l, m ...
    , @findnone, {'roi-grid-index-NaN'} ...
    , @findnone, {sprintf('roi-grid-index-%d', face_roi_grid_index())} ...
  );
else
  plt_mask_func = @(l, m) fcat.mask(l, m ...
    , @findnone, {'roi-grid-index-NaN'} ...
  );
end

anova_outs = anova_grid_index_psth( t_mean_psth, psth_labels', plt_mask_func );
[~, anova_labs, anova_cat] = make_is_anova_significant_labels( anova_outs, spike_data.labels' );

%%  plot grid index psth

pre_post_sig_anova_labels = load_pre_post_sig_anova_labels( conf );

plot_grid_index_psth( psth, bin_t, psth_labels, rowmask(psth_labels), pre_post_sig_anova_labels ...
  , 'do_save', true ...
  , 'prefix', epoch_prefix ...
);

%%  pie % significant

plt_params = struct();
plt_params.do_save = true;
plt_params.config = conf;

if ( exclude_face_roi )
  plt_params.prefix = 'excluding-face-grid-cell';
else
  plt_params.prefix = 'with-face-grid-cell';
end

plt_params.prefix = sprintf( '%s-%s', epoch_prefix, plt_params.prefix );

plot_anova_grid_index_pie( anova_labs, anova_cat, plt_params );

%%  post hoc comparison heat map

[imgs, img_labels] = make_post_hoc_comparison_heat_map( anova_outs, exclude_face_roi, 0.05 );
plot_heat_map( imgs, img_labels' ...
  , 'c_lims', [0, 0.2] ...
  , 'do_save', true ...
  , 'prefix', epoch_prefix ...
  , 'tri_heatmap', true ...
  , 'upper_tri', strcmp(psth_epoch, 'post') ...
);

%%  venn with model

hierarch_anova_sig_cell_labels = ...
  bfw_ct.load_significant_social_cell_labels_from_anova( conf );

x_ps = find( mdl_labels, 'x-degrees' );
y_ps = find( mdl_labels, 'y-degrees' );

p_x = mdl_ps(x_ps);
p_y = mdl_ps(y_ps);

% is_sig_mdl_p = p_x < 0.05 | p_y < 0.05;
is_sig_mdl_p = p_x < 0.05;
labs = mdl_labels(x_ps);

mdl_anova_labels = make_significant_anova_labels_from_p_values( labs', is_sig_mdl_p );

plot_venn_hierarch_anova_with_control_anova( hierarch_anova_sig_cell_labels, mdl_anova_labels ...
  , 'do_save', true ...
  , 'prefix', epoch_prefix ...
  , 'control_mask', find(mdl_anova_labels, 'x-degrees') ...
);

%%  venn

hierarch_anova_sig_cell_labels = ...
  bfw_ct.load_significant_social_cell_labels_from_anova( conf );

plot_venn_hierarch_anova_with_control_anova( hierarch_anova_sig_cell_labels, anova_labs ...
  , 'do_save', true ...
  , 'prefix', epoch_prefix ...
  , 'lims', [-20, 20] ...
);

%%

plt_mask_func = @(l, m) fcat.mask(l, m, @findnone, {'roi-grid-index-NaN'} );

plot_grid_index_mean_psth( t_mean_psth, psth_labels', plt_mask_func );

%%

function plot_heat_map(imgs, labels, varargin)

assert_ispair( imgs, labels );

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.c_lims = [0, 1];
defaults.tri_heatmap = false;
defaults.color_func = @hot;
defaults.n_colors = 64;
defaults.upper_tri = true;
defaults.min_max_normalize = false;
params = bfw.parsestruct( defaults, varargin );

pcats = { 'region', 'roi' };
[I, p_C] = findall( labels, pcats );
axs = gobjects( numel(I), 1 );
shp = plotlabeled.get_subplot_shape( numel(I) );

if ( params.min_max_normalize )
  tot_max = max( cellfun(@(x) max(x(:)), imgs) );
  tot_min = min( cellfun(@(x) min(x(:)), imgs) );
else
  tot_min = params.c_lims(1);
  tot_max = params.c_lims(2);
end

colors = colormap;
n_colors = size( colors, 1 );

for i = 1:numel(I)
  assert( numel(I{i}) == 1 );
  img = imgs{I{i}};
  ax = subplot( shp(1), shp(2), i );
  axs(i) = ax;
  cla( ax );
  
  if ( params.tri_heatmap )
    if ( params.upper_tri )
      v = upper_tri_verts();
    else
      v = lower_tri_verts();
    end
    
    for j = 1:size(img, 1)
      for k = 1:size(img, 2)
        t = trans_tri( v, j, k );
        p = patch( 'xdata', t(:, 1), 'ydata', t(:, 2) );
        frac_color = (img(j, k) - tot_min) / (tot_max - tot_min);
        color_ind = max( 1, round(n_colors * frac_color) );
        set( p, 'facecolor', colors(color_ind, :) );
      end
    end
  else
    h = imagesc( ax, img );
  end
  
  cb = colorbar; 
  
  title( ax, strrep(strjoin(p_C(:, i), ' | '), '_', ' ') );
end

if ( ~isempty(params.c_lims) )
  shared_utils.plot.set_clims( axs, params.c_lims );
else
  shared_utils.plot.match_clims( axs );
end

if ( params.do_save )
  shared_utils.plot.fullscreen( gcf() );
  save_p = fullfile( bfw.dataroot(params.config), 'plots', 'location_control' ...
    , dsp3.datedir(), params.base_subdir, 'heatmap' );
  dsp3.req_savefig( gcf, save_p, labels, pcats, params.prefix );
end

  function p = trans_tri(v, i, j)
    p = zeros( size(v) );
    for idx = 1:size(v, 1)
      tmp = trans_ij( i, j ) * [v(idx, :), 1]';
      p(idx, :) = tmp(1:2);
    end
  end

  function t = trans_ij(i, j)
    t = eye( 3 );
    t(:, end) = [i, j, 1];
  end

  function p = lower_tri_verts()
    p = [-1, -1; ...
         1, -1;
         -1, 1] .* 0.5;
  end

  function p = upper_tri_verts()
      p = [1, 1; ...
           -1, 1;
           1, -1] .* 0.5;
  end

end

function [imgs, labels] = make_post_hoc_comparison_heat_map(anova_outs, exclude_face, alpha)

%%

[~, max_num_comp_combs] = roi_grid_comparison_possibilities( exclude_face );

each = { 'region', 'roi' };

[labels, each_I] = keepeach( anova_outs.anova_labels', each );
imgs = cell( numel(each_I), 1 );

for i = 1:numel(each_I)
  each_ind = each_I{i};
  comps = anova_outs.comparison_tables(each_ind);
  
  img = zeros( 3 );
  denom = 0;
  
  for j = 1:numel(comps)
    c = comps{j}.comparison;
    ps = comps{j}.p_value;
    
    if ( ~isempty(c) )
      c = cellfun( @(x) strrep(x, 'roi-grid-index-', ''), c, 'un', 0 );
      v_ind = cellfun( @(x) strfind(x, 'vs.'), c, 'un', 0 );
      [a, b] = cellfun( @(x, y) deal(x(1:(y-1)), x(y+numel('vs.'):end)), c, v_ind, 'un', 0 );
      a = str2double( a );
      b = str2double( b );
      assert( ~any(isnan(a)) && ~any(isnan(b)), 'Failed to parse grid cell index.' );
      
      combined = [a, b];
      combined = sort( combined, 2 );
      assert( rows(unique(combined, 'rows')) == numel(a) );
      keep_combined = ps < alpha;
      combined = combined(keep_combined, :);
      
      for k = 1:size(combined, 1)
        a1 = combined(k, 1);
        a2 = combined(k, 2);
        img(a1) = img(a1) + 1;
        img(a2) = img(a2) + 1;
      end
    end
    
    denom = denom + max_num_comp_combs;
  end
  
  img = img / denom;
  imgs{i} = img;
end

end

function [c, max_num] = roi_grid_comparison_possibilities(exclude_face)

v = 1:9;
max_num = 8;

if ( exclude_face )
  v(face_roi_grid_index()) = [];
  max_num = 7;
end

[a, b] = ndgrid( v, v );
c = [ a(:), b(:) ];
same = c(:, 1) == c(:, 2);
c(same, :) = [];

end

function ind = find_many(labels, c, varargin)

ind = [];
for i = 1:size(c, 1)
  ind = union( ind, find(labels, c(i, :), varargin{:}) );
end

end

function mdl_labels = make_significant_anova_labels_from_p_values(mdl_labels, is_sig)

assert_ispair( is_sig, mdl_labels );

addsetcat( mdl_labels, 'anova-significant', 'anova-significant-false' );
setcat( mdl_labels, 'anova-significant', 'anova-significant-true', find(is_sig) );

end

function plot_venn_hierarch_anova_with_control_anova(hierarch_labels, control_labels, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.lims = [-13, 13];
defaults.control_mask = rowmask( control_labels );
params = bfw.parsestruct( defaults, varargin );

%%

unit_cats = {'unit_uuid', 'region', 'session'};

% h_all_combs = combs( hierarch_labels, unit_cats );
% ctrl_all_combs = combs( control_labels, unit_cats );
% shared_all_combs = cellstr( ...
%   intersect(categorical(h_all_combs'), categorical(ctrl_all_combs'), 'rows') );
% 
% base_mask_ctrl = find_many( control_labels, shared_all_combs );
% base_mask_h = find_many( hierarch_labels, shared_all_combs );

base_mask_ctrl = params.control_mask;
base_mask_h = rowmask( hierarch_labels );

pcats = {'roi', 'region'};
[control_I, ctrl_C] = findall( control_labels, pcats, base_mask_ctrl );

shp = plotlabeled.get_subplot_shape( numel(control_I) );
axs = gobjects( numel(control_I), 1 );
clf();

for i = 1:numel(control_I)
  ax = subplot( shp(1), shp(2), i );
  axs(i) = ax;
  
  control_sig_mask = find( control_labels, 'anova-significant-true', control_I{i} );
  control_combs = combs( control_labels, unit_cats, control_sig_mask );
  control_cat = categorical( control_combs' );
  
  h_sig_mask = find( hierarch_labels, 'significant', base_mask_h );
  h_sig_mask = find( hierarch_labels, ctrl_C(2, i), h_sig_mask );
  h_sig_combs = combs( hierarch_labels, unit_cats, h_sig_mask );
  h_sig_cat = categorical( h_sig_combs' );
  
  num_h = size( setdiff(h_sig_cat, control_cat, 'rows'), 1 );
  num_ctrl = size( setdiff(control_cat, h_sig_cat, 'rows'), 1 );
  num_shared = size( intersect(h_sig_cat, control_cat, 'rows'), 1 );
  
  num_units = num_h + num_ctrl + num_shared;
  
  p_h = num_h/num_units * 1e2;
  p_ctrl = num_ctrl/num_units * 1e2;
  p_shared = num_shared/num_units * 1e2;
  
  [v, s] = venn( [num_h + num_shared, num_ctrl+num_shared], num_shared );
  
  text( s.Position(1, 1), s.Position(1, 2)+2, sprintf('H-Anova: %d (%0.2f%%)', num_h+num_shared, p_h) );
  text( s.Position(2, 1), s.Position(2, 2), sprintf('Ctrl: %d (%0.2f%%)', num_ctrl+num_shared, p_ctrl) );  
  text( s.ZoneCentroid(3, 1), s.ZoneCentroid(3, 2) - 2, sprintf('Shared: %d (%0.2f%%)', num_shared, p_shared) );
  
  title( ax, strrep(strjoin(ctrl_C(:, i), ' | '), '_', ' ') );
end

shared_utils.plot.set_xlims( axs, params.lims );
shared_utils.plot.set_ylims( axs, params.lims );

if ( params.do_save )
  shared_utils.plot.fullscreen( gcf() );
  save_p = fullfile( bfw.dataroot(params.config), 'plots', 'location_control' ...
    , dsp3.datedir(), params.base_subdir, 'venn' );
  dsp3.req_savefig( gcf, save_p, control_labels, pcats, params.prefix );
end

end

function [is_sig, plt_labels, anova_cat] = ...
  make_is_anova_significant_labels(anova_outs, psth_labels)

ps = cellfun( @(x) x.Prob_F{1}, anova_outs.anova_tables );
is_sig = ps < 0.05;

anova_cat = 'anova-significant';
plt_labels = anova_outs.anova_labels';

units_each = { 'unit_uuid', 'region', 'session' };
unit_combs = combs( psth_labels, units_each );

check_anova_each = { 'roi' };

anova_I = findall( plt_labels, check_anova_each );
new_labels = plt_labels';

for i = 1:numel(anova_I)
  for j = 1:size(unit_combs, 2)
    ind = find( plt_labels, unit_combs(:, j), anova_I{i} );
    
    if ( isempty(ind) )
      append1( new_labels, plt_labels, anova_I{i} );
      is_sig(end+1) = false;
      setcat( new_labels, units_each, unit_combs(:, j), rows(new_labels) );
    end
  end
end

plt_labels = new_labels;

addsetcat( plt_labels, anova_cat, 'anova-significant-false' );
setcat( plt_labels, anova_cat, 'anova-significant-true', find(is_sig) );

end

function plot_linear_model_scatters(models, labels, varargin)

assert_ispair( models, labels );

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
params = bfw.parsestruct( defaults, varargin );

shp = plotlabeled.get_subplot_shape( numel(models) );
axs = gobjects( numel(models), 1 );
is_sig = false( size(axs) );

for i = 1:numel(models)
  ax = subplot( shp(1), shp(2), i );
  axs(i) = ax;
  cla( ax );
  
  x = models{i}.Variables.x1;
  y = models{i}.Variables.y;
  
  nans = isnan( x ) | isnan( y );
  
  scatter( ax, x(~nans), y(~nans) );
  ps = polyfit( x(~nans), y(~nans), 1 );
  px = get( ax, 'xtick' );
  py = polyval( ps, px );
  hold( ax, 'on' );
  plot( ax, px, py );
  
  title_labs = cellstr( labels, {'unit_uuid', 'region', 'position-kind'}, i );
  title_str = strrep( strjoin(title_labs, ' | '), '_', ' ' );
  
  if ( models{i}.Coefficients.pValue(2) < 0.05 )
    title_str = sprintf( '%s (*)', title_str );
    is_sig(i) = true;
  end
  
  title( ax, title_str );
  xlabel( ax, 'Degrees' );
  ylabel( ax, 'Mean spike count' );
end

if ( params.do_save )  
  save_p = fullfile( bfw.dataroot(params.config), 'plots', 'location_control' ...
    , dsp3.datedir(), params.base_subdir, 'scatter' );
  
  if ( numel(is_sig) == 1 )
    sig_dir = ternary( is_sig, 's', 'ns' );
    reg_dir = char( cellstr(labels, 'region', 1) );
    addtl_subdir = sprintf( '%s-%s', sig_dir, reg_dir );
    save_p = fullfile( save_p, addtl_subdir );
  end
  
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, labels, {'region', 'unit_uuid', 'position-kind'} ...
    , params.prefix );
end

end

function plot_linear_model_p_sig(ps, labels, varargin)

assert_ispair( ps, labels );

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
params = bfw.parsestruct( defaults, varargin );

plt_labels = labels';
addsetcat( plt_labels, 'is-sig', 'is-sig-false' );
setcat( plt_labels, 'is-sig', 'is-sig-true', find(ps < 0.05) );

[props, prop_labels] = proportions_of( plt_labels, {'region', 'position-kind'}, 'is-sig' );
pl = plotlabeled.make_common();
pl.pie_include_percentages = true;
axs = pl.pie( props * 1e2, prop_labels, 'is-sig', {'region', 'position-kind'} );

if ( params.do_save )
  save_p = fullfile( bfw.dataroot(params.config), 'plots', 'location_control' ...
    , dsp3.datedir(), params.base_subdir, 'pie' );
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, prop_labels, {'region', 'position-kind'}, params.prefix );
end

%%  p dist

pl = plotlabeled.make_common();
axs = pl.hist( ps, labels', {'region', 'position-kind'}, 20 );

if ( params.do_save )
  save_p = fullfile( bfw.dataroot(params.config), 'plots', 'location_control' ...
    , dsp3.datedir(), params.base_subdir, 'p-hist' );
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, prop_labels, {'region', 'position-kind'}, params.prefix );
end

end

function plot_anova_grid_index_pie(plt_labels, anova_cat, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
params = bfw.parsestruct( defaults, varargin );

%%

[props, prop_labels] = proportions_of( plt_labels, {'region', 'roi'}, anova_cat );
pl = plotlabeled.make_common();
pl.pie_include_percentages = true;
axs = pl.pie( props * 1e2, prop_labels, anova_cat, {'region', 'roi'} );

if ( params.do_save )
  save_p = fullfile( bfw.dataroot(params.config), 'plots', 'location_control' ...
    , dsp3.datedir(), params.base_subdir, 'pie' );
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, prop_labels, {'region', 'roi'}, params.prefix );
end

end

function plot_grid_index_psth(psth, bin_t, labels, mask, anova_labs, varargin)

assert_ispair( psth, labels );
assert( numel(bin_t) == size(psth, 2) );

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
params = bfw.parsestruct( defaults, varargin );

fig_cats = {'unit_uuid', 'region', 'session', 'roi'};
[fig_I, fig_C] = findall( labels, fig_cats, mask );

subplot_shape = [3, 3];
inds = 1:9;
inds(5) = [];
colors = spring( 9 );

for i = 1:numel(fig_I)
  shared_utils.general.progress( i, numel(fig_I) );
  
  clf();
  axs = gobjects( numel(inds), 1 );
  match_anova_ind = find( anova_labs, fig_C(:, i) );
  region_lab = fig_C{2, i};
  
  if ( numel(match_anova_ind) == 1 )
    sig_label = char( cellstr(anova_labs, 'anova-significant', match_anova_ind) );
  else
    sig_label = '';
  end
  
  for j = 1:numel(inds)
    ind = inds(j);
    ax = subplot( subplot_shape(1), subplot_shape(2), ind );
    cla( ax );
    hold( ax, 'on' );
    axs(j) = ax;
    
    search_for = roi_grid_index_label( ind );
    search_ind = find( labels, search_for, fig_I{i} );
    
    m = nanmean( psth(search_ind, :), 1 );
    err = plotlabeled.nansem( psth(search_ind, :) );
    
    h0 = plot( ax, bin_t, m );
    h1 = plot( ax, bin_t, m - err );
    h2 = plot( ax, bin_t, m + err );
    
    hs = [h0, h1, h2];
    arrayfun( @(x) set(x, 'color', colors(ind, :)), hs, 'un', 0 );
  end
  
  title_labs = strrep( strjoin(fig_C(:, i), ' | '), '_', ' ' );
  
  if ( ~isempty(sig_label) )
    title_labs = sprintf( '%s (%s)', title_labs, sig_label );
  end
  
  title( axs(1), title_labs );
  ylabel( axs(1), 'Spike count' );
  
  shared_utils.plot.match_xlims( axs );
  shared_utils.plot.match_ylims( axs );
  
  if ( params.do_save )
    shared_utils.plot.fullscreen( gcf() );
    save_p = fullfile( bfw.dataroot(params.config), 'plots', 'location_control' ...
      , dsp3.datedir(), params.base_subdir, 'psth' );
    
    addtl_subdir = sprintf( '%s/%s', sig_label, region_lab );
    save_p = fullfile( save_p, addtl_subdir );
    
    dsp3.req_savefig( gcf, save_p, prune(labels(fig_I{i})), fig_cats, params.prefix );
  end
end

end

function anova_outs = anova_grid_index_psth(psth, labels, mask_func)

assert_ispair( psth, labels );
assert( isvector(psth) );

each = { 'unit_uuid', 'region', 'session', 'roi' };
factor = 'roi-grid-index';

mask = mask_func( labels, rowmask(labels) );

anova_outs = dsp3.anova1( psth, labels, each, factor ...
  , 'mask', mask ...
  , 'remove_nonsignificant_comparisons', false ...
);

end

function plot_grid_index_mean_psth(psth, labels, mask_func)

assert_ispair( psth, labels );

pl = plotlabeled.make_common();
pcats = { 'roi' };
gcats = {};
xcats = { 'roi-grid-index' };

plt_mask = mask_func( labels, rowmask(labels) );
axs = pl.bar( psth(plt_mask), labels(plt_mask), xcats, gcats, pcats );

end

function [psth, psth_labels, bin_t, all_event_inds, all_pos_inds] = ...
  make_psth(spike_ts, spike_labels, start_ts, event_inds, event_labels, params)

assert_ispair( spike_ts, spike_labels );
assert_ispair( event_inds, event_labels );

t_win = params.t_win;
bin_width = params.bin_width;

psth = cell( numel(spike_ts), 1 );
all_event_inds = cell( size(psth) );
all_pos_inds = cell( size(psth) );
bin_t = [];
psth_labels = fcat();

for i = 1:numel(spike_ts)
  shared_utils.general.progress( i, numel(spike_ts) );
  
  ts = spike_ts{i};
  run_name = cellstr( spike_labels, 'session', i );
  run_match = find( event_labels, run_name );
  
  event_inds_this_run = event_inds(run_match);
  events = start_ts(event_inds_this_run);
  [tmp_psth, bin_t] = bfw.trial_psth( ts, events, t_win(1), t_win(2), bin_width );
  
  new_labels = append( fcat, event_labels, run_match );
  join( new_labels, prune(spike_labels(i)) );
  append( psth_labels, new_labels );
  
  psth{i} = tmp_psth;
  all_event_inds{i} = event_inds_this_run;
  all_pos_inds{i} = run_match;
end

psth = vertcat( psth{:} );
all_event_inds = vertcat( all_event_inds{:} );
all_pos_inds = vertcat( all_pos_inds{:} );

assert_ispair( psth, psth_labels );

end

function [labels, grid_cat] = apply_grid_index_labels(labels, grid_indices)

grid_cat = 'roi-grid-index';
assert_ispair( grid_indices, labels );
addcat( labels, grid_cat );
inds = arrayfun( @(x) sprintf('%s-%s', grid_cat, num2str(x)), grid_indices, 'un', 0 );

if ( ~isempty(labels) )
  setcat( labels, grid_cat, inds );
end

end

function [grid_indices, pos_degrees] = roi_centered_grid_indices(pos, labels, roi_files, run_I)

assert_ispair( pos, labels );
grid_indices = nan( rows(pos), 1 );
pos_degrees = nan( rows(pos), 2 );

for i = 1:numel(run_I)
  run_ind = run_I{i};
  
  for j = 1:numel(run_ind)
    trial_ind = run_ind(j);    
    p = pos(trial_ind, :);
    
    search_for = cellstr( labels, {'unified_filename'}, trial_ind );
    roi_match = find( roi_files.labels, [search_for, {'whole_face', 'm1'}] );
    
    if ( ~isempty(roi_match) )
      assert( numel(roi_match) == 1, 'Expected 1 or 0 matches for roi.' );
      
      roi = roi_files.rects(roi_match, :);
      
      grid_indices(trial_ind) = roi_centered_grid_index( p, roi );
      
      [deg_x, deg_y] = roi_centered_degrees( p, roi );
      pos_degrees(trial_ind, :) = [deg_x, deg_y];
    end
  end
end

end

function [x, y] = roi_centered_degrees(pos, roi)

center = shared_utils.rect.center( roi );
delta = pos(:) - center(:);
x = bfw.px2deg( delta(1) );
y = bfw.px2deg( delta(2) );

end

function grid_index = roi_centered_grid_index(pos, roi)

w = shared_utils.rect.width( roi );
h = shared_utils.rect.height( roi );

x0 = roi(1) - w;
x1 = roi(1);
x2 = roi(3);
x3 = roi(3) + w;

y0 = roi(2) - h;
y1 = roi(2);
y2 = roi(4);
y3 = roi(4) + h;

rects = zeros( 9, 4 );

rects(1, :) = [x0, y0, x1, y1];
rects(2, :) = [x0, y1, x1, y2];
rects(3, :) = [x0, y2, x1, y3];

rects(4, :) = [x1, y0, x2, y1];
rects(5, :) = [x1, y1, x2, y2];
rects(6, :) = [x1, y2, x2, y3];

rects(7, :) = [x2, y0, x3, y1];
rects(8, :) = [x2, y1, x3, y2];
rects(9, :) = [x2, y2, x3, y3];

for i = 1:size(rects, 1)
  if ( bfw.bounds.rect(pos(1), pos(2), rects(i, :)) )
    grid_index = i;
    return
  end
end

grid_index = nan;

end

function [all_event_inds, event_ind_labels] = ...
  preceding_event_indices(start_ts, labels, run_I, roi_mask_func, params)

assert_ispair( start_ts, labels );

thresh = params.threshold;
exclude_same_roi = params.exclude_same_roi_events;

all_event_inds = [];
event_ind_labels = fcat();

for i = 1:numel(run_I)
  run_ind = run_I{i};
  run_ts = start_ts(run_ind);
  assert( issorted(run_ts), 'Expected run-level event times to be sorted.' );
  
  [roi_I, rois] = findall( labels, 'roi', roi_mask_func(labels, run_ind) );
  
  for j = 1:numel(roi_I)
    roi_ind = roi_I{j};
    roi_ts = start_ts(roi_ind);

    prev_event_inds = nan( size(roi_ind) );

    for k = 1:numel(roi_ts)
      delta = roi_ts(k) - run_ts;
      ib_ind = delta >= thresh(1) & delta <= thresh(2) & delta ~= 0;
      
      if ( exclude_same_roi )
        % If any of the fixations in the preceding window were fixations to
        % the target roi, consider the period "contaminated" by that
        % fixation, and don't consider it.
        prev_rois = cellstr( labels, 'roi', run_ind(ib_ind) );
        
        if ( any(strcmp(prev_rois, rois{j})) )
          ib_ind(:) = false;
        end
      end
      
      first_match = find( ib_ind, 1, 'last' );

      if ( ~isempty(first_match) )
%         prev_event_inds(k) = roi_ind(k);
        prev_event_inds(k) = run_ind(first_match);
      end
    end

    keep_inds = find( ~isnan(prev_event_inds) );

    append( event_ind_labels, labels, roi_ind(keep_inds) );
    all_event_inds = [ all_event_inds; prev_event_inds(keep_inds) ];
  end
end

end

function [all_event_inds, event_ind_labels] = ...
  event_indices_excluding_target_rois(start_ts, labels, run_I, exclude_rois, time_thresh)

assert_ispair( start_ts, labels );

all_event_inds = [];
event_ind_labels = fcat();

for i = 1:numel(run_I)
  run_ind = run_I{i};
  run_ts = start_ts(run_ind);
  assert( issorted(run_ts), 'Expected run-level event times to be sorted.' );
  
  keep_inds = findnone( labels, exclude_rois, run_ind );
  keep_keep = true( size(keep_inds) );
  
  for j = 1:numel(keep_inds)
    t_min = start_ts(keep_inds(j)) + time_thresh(1);
    t_max = start_ts(keep_inds(j)) + time_thresh(2);
    
    within_range = run_ts >= t_min & run_ts <= t_max;
    maybe_excluded_roi = find( labels, exclude_rois, run_ind(within_range) );
    
    if ( ~isempty(maybe_excluded_roi) )
      % an event to an excluded roi occurs within [time_thresh(1), time_thresh(2)]
      % of the event given by keep_inds(j), so exclude it.
      keep_keep(j) = false;
    end
  end
  
  all_keep = keep_inds(keep_keep);
  all_event_inds = [ all_event_inds; all_keep ];
  append( event_ind_labels, labels, all_keep );
end

end

function prev_event_positions = ...
  preceding_event_positions(start_ts, stop_ts, sample_ts, positions, ...
    event_labels, sample_labels, event_mask)

assert_ispair( start_ts, event_labels );
assert_ispair( stop_ts, event_labels );
assert_ispair( sample_ts, sample_labels );
assert_ispair( positions, sample_labels );

prev_event_positions = nan( numel(event_mask), 2 );

for i = 1:numel(event_mask)    
  run_name = cellstr( event_labels, 'unified_filename', event_mask(i) );
  sample_run_match = find( sample_labels, run_name );
  
  if ( ~isempty(sample_run_match) )
    assert( numel(sample_run_match) == 1 );
    
    evt_start = start_ts(event_mask(i));
    evt_stop = stop_ts(event_mask(i));
  
    t_ind = sample_ts{sample_run_match} >= evt_start & ...
      sample_ts{sample_run_match} <= evt_stop;
    
    p_evt = nanmean( positions{sample_run_match}(:, t_ind), 2 );
    
    prev_event_positions(i, :) = p_evt;
  end
end

end

function [mdl, mdl_labels] = pos_linear_model(x, y, labels, mask)

assert_ispair( x, labels );
assert_ispair( y, labels );
assert( isvector(x) && isvector(y) ...
  , 'Expected response and predictors to be vectors.' );

mdl = fitlm( x(mask), y(mask) );
mdl_labels = append1( fcat, labels, mask );

end

function labels = load_pre_post_sig_anova_labels(conf)

if ( nargin < 1 )
  conf = bfw.config.load();
end

ctrl_dir = fullfile( bfw.dataroot(conf), 'analyses', 'spatial_bin_control' );
pre_file = fullfile( ctrl_dir, 'pre_eyes_anova_labels.mat' );
post_file = fullfile( ctrl_dir, 'post_eyes_anova_labels.mat' );

pre_labs = shared_utils.io.fload( pre_file );
post_labs = shared_utils.io.fload( post_file );

assert( isequal(size(pre_labs), size(post_labs)) );
labels = pre_labs';

for i = 1:size(pre_labs, 1)
  sig_pre = strcmp( cellstr(pre_labs, 'anova-significant', i), 'anova-significant-true' );
  sig_post = strcmp( cellstr(post_labs, 'anova-significant', i), 'anova-significant-true' );
  
  base_label = '';
  
  if ( sig_pre )
    base_label = sprintf( '%ssig-pre-', base_label );
  end
  if ( sig_post )
    base_label = sprintf( '%ssig-post-', base_label );
  end
  if ( isempty(base_label) )
    base_label = 'ns';
  end
  
  setcat( labels, 'anova-significant', base_label, i );
end

end

function l = roi_grid_index_label(i)
l = sprintf( 'roi-grid-index-%d', i );
end

function i = face_roi_grid_index()
i = 5;
end

function [event_inds, event_ind_labels] = find_most_events(start_ts, evt_labels)

assert_ispair( start_ts, evt_labels );

run_mask = fcat.mask( evt_labels, find(~isnan(start_ts)) ...
  , @find, {'m1', 'mutual'} ...
);

event_inds = run_mask;
event_ind_labels = prune( evt_labels(run_mask) );

end

function [event_inds, event_ind_labels] = find_events_excluding_target_rois(start_ts, evt_labels)

assert_ispair( start_ts, evt_labels );

time_thresh = [-0.5, 0.5];

run_mask = fcat.mask( evt_labels, find(~isnan(start_ts)) ...
  , @find, {'m1', 'mutual'} ...
);

run_I = findall( evt_labels, 'unified_filename', run_mask );
exclude_rois = { 'eyes_nf', 'whole_face', 'face' };

[event_inds, event_ind_labels] = ...
  event_indices_excluding_target_rois( start_ts, evt_labels, run_I, exclude_rois, time_thresh );

end

function [event_inds, event_ind_labels] = find_preceding_event_indices(start_ts, evt_labels)

assert_ispair( start_ts, evt_labels );

roi_mask_func = @(l, m) fcat.mask(l, m ...
  , @findor, {'whole_face', 'eyes_nf'} ...
);

run_mask = fcat.mask( evt_labels, find(~isnan(start_ts)) ...
  , @find, {'m1', 'mutual'} ...
);

run_I = findall( evt_labels, 'unified_filename', run_mask );
precede_params = struct( ...
    'threshold', [0, 0.5] ...
  , 'exclude_same_roi_events', true ...
);

[event_inds, event_ind_labels] = ...
  preceding_event_indices( start_ts, evt_labels, run_I, roi_mask_func, precede_params );

end

function [mdls, mdl_ps, p_perm_sig, mdl_labels] = degree_linear_model(t_mean_psth, psth_event_pos, psth_labels, varargin)

assert_ispair( t_mean_psth, psth_labels );
assert_ispair( psth_event_pos, psth_labels );

defaults = struct();
defaults.permute = false;
defaults.iters = 1e3;
defaults.rng_state = [];
params = bfw.parsestruct( defaults, varargin );

do_permute = params.permute;
rng_state = params.rng_state;

if ( ~isempty(rng_state) )
  s = rng();
  cleanup = onCleanup( @() rng(s) );
  rng( rng_state );
end

mdl_each = { 'unit_uuid', 'region', 'session' };
mdl_I = findall( psth_labels, mdl_each );

mdls = {};
mdl_labels = fcat;
p_perm_sig = [];

pos_kinds = { 'x-degrees', 'y-degrees' };

for i = 1:2
  deg = psth_event_pos(:, i);
  non_nan_deg = find( ~isnan(deg) );
  pos_kind = pos_kinds{i};

  for j = 1:numel(mdl_I)    
    shared_utils.general.progress( j, numel(mdl_I) );
    
    mdl_ind = mdl_I{j};
    mdl_ind = intersect( mdl_ind, non_nan_deg );
    
    [mdl, tmp_labels] = pos_linear_model( deg, t_mean_psth, psth_labels, mdl_ind );
    addsetcat( tmp_labels, 'position-kind', pos_kind );
    
    append( mdl_labels, tmp_labels );
    mdls{end+1, 1} = mdl;
    real_beta = mdl.Coefficients.Estimate(2);
    
    if ( do_permute )
      met_crit = false( params.iters, 1 );
      
      for k = 1:params.iters
        tmp_deg = deg;
        perm_ind = randperm( numel(mdl_ind) );
        tmp_deg(mdl_ind) = tmp_deg(mdl_ind(perm_ind));
        
        null_mdl = pos_linear_model( tmp_deg, t_mean_psth, psth_labels, mdl_ind );
        null_beta = null_mdl.Coefficients.Estimate(2);
        
        if ( real_beta < 0 )
          crit = real_beta < null_beta;
        else
          crit = real_beta > null_beta;
        end
        
        met_crit(k) = crit;
      end
      
      p_perm_sig(end+1, 1) = 1 - pnz( met_crit );
    else
      p_perm_sig(end+1, 1) = nan;
    end
  end
end

assert_ispair( mdls, mdl_labels );
mdl_ps = cellfun( @(x) x.Coefficients.pValue(2), mdls );
assert_ispair( mdl_ps, mdl_labels );
assert_ispair( p_perm_sig, mdl_labels );

end

function sorted_events = load_events(conf, use_whole_face)

sorted_events = shared_utils.io.fload( fullfile(bfw.dataroot(conf) ...
  , 'analyses/events/sorted_events.mat') );

if ( use_whole_face )
  [~, transform_ind] = bfw.make_whole_face_roi( sorted_events.labels );
  sorted_events.events = sorted_events.events(transform_ind, :);

  rm_ind = find( sorted_events.labels, {'eyes_nf', 'face'} );
  keep_ind = setdiff( rowmask(sorted_events.labels), rm_ind );

  sorted_events.events(rm_ind, :) = [];
  keep( sorted_events.labels, keep_ind );

  assert_ispair( sorted_events.events, sorted_events.labels );

  sorted_events = bfw.sort_events( sorted_events );
end

end

function state = load_rng_state(conf)

state_file = fullfile( bfw.dataroot(conf), 'analyses' ...
  , 'spatial_bin_control', 'rng_102720.mat' );
state = shared_utils.io.fload( state_file );

end

function roi_files = load_roi_files(conf)

roi_files = bfw_gather_rois( 'config', conf );
replace( roi_files.labels, 'face', 'whole_face' );

end

function sample_files = load_sample_files(conf)

sample_files = bfw_gather_aligned_samples( ...
  'input_subdirs', {'position', 'time'} ...
  , 'config', conf ...
);

end

function spike_data = load_spike_data(conf)

spike_data = bfw_gather_spikes( ...
  'config', conf ...
  , 'spike_subdir', 'cc_spikes' ...
  , 'is_parallel', true ...
);

bfw.add_monk_labels( spike_data.labels );

end

function [dest_psth, dest_labels, dest_pos] = collapse_degree_bins(psth, labels, pos)

%%

assert_ispair( psth, labels );
assert_ispair( pos, labels );

assert( isvector(psth), 'Expected time-averaged psth.' );
assert( size(pos, 2) == 2, 'Expected 2 columns to degree position.' );

all_p = pos(:);
all_vs = unique( all_p(~isnan(all_p)) );
unit_I = findall( labels, {'unit_uuid', 'region', 'session'} );

dest_psth = [];
dest_labels = fcat();
dest_pos = [];

for i = 1:2
  p = pos(:, i);
  all_inds = arrayfun( @(x) find(p == x), all_vs, 'un', 0 );
  
  if ( i == 1 )
    dest_ind = 1;
    null_ind = 2;
  else
    dest_ind = 2;
    null_ind = 1;
  end
  
  dest_p = zeros( 2, 1 );
  
  for j = 1:numel(unit_I)
    shared_utils.general.progress( j, numel(unit_I) );
    
    ind = unit_I{j};
    l = append1( fcat, labels, ind );
    repmat( l, numel(all_inds) );
    append( dest_labels, l );
    
    for k = 1:numel(all_inds)
      full_ind = intersect( ind, all_inds{k} );
      mu = nanmean( psth(full_ind) );
     
      dest_p(dest_ind) = all_vs(k);
      dest_p(null_ind) = nan;
      
      dest_psth(end+1, 1) = mu;
      dest_pos(end+1, :) = dest_p;
    end
  end
end

assert_ispair( dest_psth, dest_labels );
assert_ispair( dest_pos, dest_labels );

end

function inds = degree_bin_indices(deg, min, max, num_bins)

assert( isvector(deg), 'Expected a vector of degrees.' );
deg(deg < min) = min;
deg(deg > max) = max;

span = max - min;
space = span / num_bins;
edges = min:space:max;

inds = nan( size(deg) );
zero_bin = edges == 0;
assert( nnz(zero_bin) == 1, 'Expected 1 zero bin.' );
zero_bin = find( zero_bin );

for i = 1:numel(edges)-1  
  if ( i == numel(edges)-1 )
    ind = deg >= edges(i);
  else
    ind = deg >= edges(i) & deg < edges(i+1);
  end
  
  inds(ind) = edges(i);
end

end

function [psth, psth_labels, bin_t, psth_event_inds, psth_pos_inds, psth_event_pos] = load_post_psth(conf)

file_p = fullfile( bfw.dataroot(conf), 'analyses', 'spatial_bin_control' ...
  , 'complete_post_psth_eyes.mat' );

file = load( file_p );

psth = file.psth;
psth_labels = file.psth_labels;
bin_t = file.bin_t;
psth_event_inds = file.psth_event_inds;
psth_pos_inds = file.psth_pos_inds;
pos_degrees = file.pos_degrees;

psth_event_pos = pos_degrees(psth_pos_inds, :);

end