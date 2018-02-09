import shared_utils.io.fload;

conf = bfw.config.load();

% event_aligned_p = bfw.get_intermediate_directory( 'event_aligned_spikes' );
event_aligned_p = bfw.get_intermediate_directory( 'modulation_type' );
event_mats = shared_utils.io.find( event_aligned_p, '.mat' );

zpsth = Container();
psth = Container();
raster = Container();
null_psth = Container();

got_bin_t = false;

for i = 1:numel(event_mats)
  fprintf( '\n %d of %d', i, numel(event_mats) );
  
  spikes = shared_utils.io.fload( event_mats{i} );
  
  if ( isfield(spikes, 'is_link') && spikes.is_link ), continue; end
  
  spk_params = spikes.params;
  
  if ( ~got_bin_t )
    bint = spikes.psth_t;
    raster_t = spikes.raster_t;
    got_bin_t = true;
  end
  
  psth = psth.append( spikes.psth );
%   psth = psth.append( spikes.psth.each1d({'looks_to', 'looks_by', 'unit_uuid'}, @rowops.nanmean) );
  zpsth = zpsth.append( spikes.zpsth );
  raster = raster.append( spikes.raster );
  null_psth = null_psth.append( spikes.null );
end
% 
% [psth, ~, C] = bfw.add_unit_id( psth );
% 
% zpsth = zpsth.require_fields( 'unit_id' );
% raster = raster.require_fields( 'unit_id' );
% null_psth = null_psth.require_fields( 'unit_id' );
% 
% for i = 1:size(C, 1)
%   ind_z = zpsth.where( C(i, :) );
%   ind_r = raster.where( C(i, :) );
%   ind_n = null_psth.where( C(i, :) );
%   
%   unit_id_str = sprintf( 'unit__%d', i );
%   zpsth('unit_id', ind_z) = unit_id_str;
%   raster('unit_id', ind_r) = unit_id_str;
%   null_psth('unit_id', ind_n) = unit_id_str;
% end

psth_info_str = sprintf( 'step_%d_ms', spk_params.psth_bin_size * 1e3 );

%%  population response matrix, vs. null

specificity = { 'unit_uuid', 'looks_by', 'looks_to' };

pop_null_psth = null_psth.each1d( specificity, @rowops.nanmean );
pop_psth = psth;
pop_raster = raster;

n_event_thresh = 10;

pop_psth = pop_psth.rm( {'unit_uuid__NaN'} );
pop_null_psth = pop_null_psth.rm( {'unit_uuid__NaN'} );
pop_raster = pop_raster.rm( {'unit_uuid__NaN'} );

window_pre = spk_params.window_pre;
window_post = spk_params.window_post;

window_pre_ind = bint >= window_pre(1) & bint < window_pre(2);
window_post_ind = bint >= window_post(1) & bint < window_post(2);

modulated_psth = Container();

[I, C] = pop_psth.get_indices( specificity );

is_sig = true( numel(I), 1 );
too_few_events = false( size(is_sig) );

for i = 1:numel(I)
  fprintf( '\n %d of %d', i, numel(I) );
  
  subset_psth = pop_psth(I{i});
  subset_null = pop_null_psth(C(i, :));
  subset_raster = pop_raster(C(i, :));
  
  assert( shape(subset_psth, 1) == 1 && shapes_match(subset_psth, subset_null) );
  
  cell_type = char( subset_psth('cell_type') );
  
  sum_spikes = sum( any(subset_raster.data, 2) );
  
  if ( ~any(sum_spikes >= n_event_thresh) || shape(subset_raster, 1) < n_event_thresh )
    cell_type = 'none';
    too_few_events(i) = true;
  end
  
  real_mean_pre = nanmean( subset_psth.data(:, window_pre_ind), 2 );
  real_mean_post = nanmean( subset_psth.data(:, window_post_ind), 2 );
  
  fake_mean_pre = nanmean( subset_null.data(:, window_pre_ind), 2 );
  fake_mean_post = nanmean( subset_null.data(:, window_post_ind), 2 );
    
  switch ( cell_type )
    case 'pre'
      mod_amt = abs( real_mean_pre - fake_mean_pre );
    case 'post'
      mod_amt = abs( real_mean_post - fake_mean_post );
    case { 'pre_and_post' }
      mod_pre = abs( real_mean_pre - fake_mean_pre );
      mod_post = abs( real_mean_post - fake_mean_post );
      mod_amt = mean( [mod_pre, mod_post] );
    case 'none'
%       mod_amt = NaN;
      mod_pre = abs( real_mean_pre - fake_mean_pre );
      mod_post = abs( real_mean_post - fake_mean_post );
      mod_amt = mean( [mod_pre, mod_post] );
      is_sig(i) = false;
    otherwise
      error( 'Unrecognized cell type "%s".', cell_type );
  end
  
  modulated_psth = modulated_psth.append( set_data(subset_psth, mod_amt) );
        
end

%%  n sig

stats_each = { 'looks_to', 'looks_by', 'region' };

to_stats = pop_psth;
to_stats = to_stats( {'mutual', 'm1', 'm2'} );

n_sig = to_stats.for_each( stats_each, @counts, 'cell_type', to_stats('cell_type') );
p_sig = to_stats.for_each( stats_each, @percentages, 'cell_type', to_stats('cell_type') );

for i = 2

figure(1); clf();

pl = ContainerPlotter();
pl.y_lim = [0, 100];

if ( i == 1 )
  plt = p_sig;
  base_fname = 'population_percent_significant';
else
  plt = n_sig;
  base_fname = 'population_n_significant';
end

plt.bar( pl, 'region', {'cell_type'}, {'looks_by', 'looks_to'} );

%   save
kind = 'significant_per_region';

fname = strjoin( plt.flat_uniques({'session_name'}), '_' );
fname = sprintf( '%s_%s', base_fname, fname );
date_dir = datestr( now, 'mmddyy' );
save_plot_p = fullfile( conf.PATHS.data_root, 'plots', 'population_response' );
save_plot_p = fullfile( save_plot_p, date_dir, kind, psth_info_str );
shared_utils.io.require_dir( save_plot_p );

end

shared_utils.plot.save_fig( gcf, fullfile(save_plot_p, fname), {'epsc', 'png', 'fig'} );

%%

modulated_psth = modulated_psth( {'m1', 'mutual'} );

[I, C] = modulated_psth.get_indices( {'unit_uuid'} );

fig = figure(1); clf( fig );

x_range = 1;
y_range = 1;

colors = containers.Map();
colors( 'bla' ) = 'r';
colors( 'accg' ) = 'b';
colors( 'ofc' ) = 'g';

res = Container();

legend_components = containers.Map();

for i = 1:numel(I)
  subset = modulated_psth(I{i});
  
  subset_is_sig = is_sig(I{i});
  
  regs = subset('region');
  
  assert( numel(regs) == 1 );
  
  reg = char( regs );
  
  current_color = colors( reg );

  ind_face = subset.where( 'face' );
  ind_eyes = subset.where( 'eyes' );
  ind_mut = subset.where( 'mutual' );
  ind_excl = subset.where( {'m1'} );

  if ( ~any(ind_face) || ~any(ind_eyes) || ~any(ind_mut) || ~any(ind_excl) )
    fprintf( '\n skipping "%s"', strjoin([regs{j}, C(i, :)], ', ') );
    continue;
  end
  
  all_is_sig = any(subset_is_sig(ind_face)) && any(subset_is_sig(ind_eyes)) && ...
    any(subset_is_sig(ind_mut)) && any(subset_is_sig(ind_excl));
  all_is_sig = all( all_is_sig );

  face = subset.data(ind_face);
  eyes = subset.data(ind_eyes);
  mut = subset.data(ind_mut);
  excl = subset.data(ind_excl);
  
  face = mean( face );
  eyes = mean( eyes );
  mut = mean( mut );
  excl = mean( excl );

  eyes_over_face = (eyes-face) ./ (face + eyes);
  mut_over_excl = (mut-excl) ./ (mut + excl);

  x_coord = eyes_over_face * x_range;
  y_coord = mut_over_excl * y_range;

  pairs = field_label_pairs( one(subset) );

  res = res.append( Container([eyes_over_face, mut_over_excl], pairs{:}) );

  h = plot( x_coord, y_coord, sprintf('%so', current_color), 'markersize', 6 ); hold on;
  
  if ( all_is_sig )
    h = plot( x_coord, y_coord, sprintf('%so', current_color), 'MarkerFaceColor', current_color, 'markersize', 6 ); hold on;
  end

  if ( ~legend_components.isKey(reg) )
    legend_components(reg) = h;
  end
end

[I, C] = res.get_indices( 'region' );

corred = Container();

for i = 1:numel(I)
  reg = res(I{i});
  reg( any(isnan(reg.data), 2) ) = [];
  [r, p] = corr( reg.data(:, 1), reg.data(:, 2) );
  corred = corred.append( set_data(one(reg), [r, p]) );
end

% title( 'ACCg' );

hold on;
plot( [-1, 1], [0, 0], 'k-' );
plot( [0, 0], [-1, 1], 'k-' );

xlabel( 'eyes over face' );
ylabel( 'mutual over exclusive' );

ylim( [-1, 1] );
xlim( [-1, 1] );

axis( 'square' );

leg_keys = legend_components.keys();
leg_elements = gobjects( 1, numel(leg_keys) );

for i = 1:numel(leg_keys)
  leg_elements(i) = legend_components(leg_keys{i}); 
end

legend( leg_elements, leg_keys );

%   save
kind = 'population_matrix_from_null';

fname = strjoin( res.flat_uniques({'session_name'}), '_' );
fname = sprintf( 'population_matrix_%s', fname );
date_dir = datestr( now, 'mmddyy' );
save_plot_p = fullfile( conf.PATHS.data_root, 'plots', 'population_response' );
save_plot_p = fullfile( save_plot_p, date_dir, kind, psth_info_str );
shared_utils.io.require_dir( save_plot_p );

shared_utils.plot.save_fig( gcf, fullfile(save_plot_p, fname), {'epsc', 'png', 'fig'} );


%%  plot population response matrix

pre_bin_t = -0.2;
post_bin_t = 0.2;

use_z = false;

pre_ind = bint >= pre_bin_t & bint < 0;
post_ind = bint > 0 & bint <= post_bin_t;

if ( use_z )
  psth_cont = zpsth;
else
  psth_cont = psth;
end

psth_pre = set_data( psth_cont, nanmean(psth_cont.data(:, pre_ind), 2) );
psth_post = set_data( psth_cont, nanmean(psth_cont.data(:, post_ind), 2) );

psth_modulation = (psth_post.data - psth_pre.data) ./ (psth_post.data + psth_pre.data);

psth_modulation = abs( psth_modulation );

psth_modulation = set_data( psth_post, psth_modulation );

psth_modulation = psth_modulation.each1d( {'unit_id', 'looks_by', 'looks_to'}, @rowops.nanmean );

psth_modulation = psth_modulation({'m1', 'mutual'});

[I, C] = psth_modulation.get_indices( {'unit_id'} );

modulation_index = Container();

fig = figure(1); clf( fig );

x_range = 1;
y_range = 1;

colors = containers.Map();
colors( 'bla' ) = 'r';
colors( 'accg' ) = 'b';

res = Container();

legend_components = containers.Map();

for i = 1:numel(I)
  subset = psth_modulation(I{i});
  
  regs = subset('region');
  
  assert( numel(regs) == 1 );
  
  reg = char( regs );
  
  current_color = colors( reg );

  ind_face = subset.where( 'face' );
  ind_eyes = subset.where( 'eyes' );
  ind_mut = subset.where( 'mutual' );
  ind_excl = subset.where( {'m1'} );

  if ( ~any(ind_face) || ~any(ind_eyes) || ~any(ind_mut) || ~any(ind_excl) )
    fprintf( '\n skipping "%s"', strjoin([regs{j}, C(i, :)], ', ') );
    continue;
  end

  face = subset.data(ind_face);
  eyes = subset.data(ind_eyes);
  mut = subset.data(ind_mut);
  excl = subset.data(ind_excl);

  eyes_over_face = (eyes-face) ./ (face + eyes);
  mut_over_excl = (mut-excl) ./ (mut + excl);

  x_coord = eyes_over_face * x_range;
  y_coord = mut_over_excl * y_range;

  pairs = field_label_pairs( one(subset) );

  res = res.append( Container([eyes_over_face, mut_over_excl], pairs{:}) );

  h = plot( x_coord, y_coord, sprintf('%so', current_color), 'MarkerFaceColor', current_color, 'markersize', 6 ); hold on;

  if ( ~legend_components.isKey(reg) )
    legend_components(reg) = h;
  end
end

[I, C] = res.get_indices( 'region' );

corred = Container();

for i = 1:numel(I)
  reg = res(I{i});
  reg( any(isnan(reg.data), 2) ) = [];
  [r, p] = corr( reg.data(:, 1), reg.data(:, 2) );
  corred = corred.append( set_data(one(reg), [r, p]) );
end

% title( 'ACCg' );

hold on;
plot( [-1, 1], [0, 0], 'k-' );
plot( [0, 0], [-1, 1], 'k-' );

xlabel( 'eyes over face' );
ylabel( 'mutual over exclusive' );

ylim( [-1, 1] );
xlim( [-1, 1] );

axis( 'square' );

leg_keys = legend_components.keys();
leg_elements = gobjects( 1, numel(leg_keys) );

for i = 1:numel(leg_keys)
  leg_elements(i) = legend_components(leg_keys{i}); 
end

legend( leg_elements, leg_keys );

%   save
kind = 'population_matrix';

if ( use_z )
  kind = sprintf( '%s_z', kind );
end

fname = strjoin( res.flat_uniques({'session_name'}), '_' );
fname = sprintf( 'population_matrix_%s', fname );
date_dir = datestr( now, 'mmddyy' );
save_plot_p = fullfile( conf.PATHS.data_root, 'plots', 'population_response' );
save_plot_p = fullfile( save_plot_p, date_dir, kind, psth_info_str );
shared_utils.io.require_dir( save_plot_p );

shared_utils.plot.save_fig( gcf, fullfile(save_plot_p, fname), {'epsc', 'png', 'fig'} );

%%  per unit non-z

pl = ContainerPlotter();

date_dir = datestr( now, 'mmddyy' );

selectors = { '01162018', '01172018', 'm1', 'm2', 'mutual' };
plt = psth.only( selectors );

kind = 'per_unit';

append_null = true;

save_plot_p = fullfile( conf.PATHS.data_root, 'plots', 'psth' );
save_plot_p = fullfile( save_plot_p, date_dir, kind );
save_plot_p = fullfile( save_plot_p, psth_info_str );

shared_utils.io.require_dir( save_plot_p );

[I, C] = plt.get_indices( {'unit_id'} );

f = figure(1);

for i = 1:numel(I)
  fprintf( '\n %d of %d', i, numel(I) );
  subset = plt(I{i});
  
  subset = subset.require_fields( 'kind' );
  subset('kind') = 'real';
  
  if ( append_null )
    unqs = C(i, :);
    unqs = union( unqs, subset.flat_uniques({'looks_by', 'looks_to', 'region'}) );

    matching_null = null_psth.only( unqs );

    matching_null = matching_null.require_fields( 'kind' );

    matching_null('kind') = 'null';

    subset = subset.append( matching_null );
  end
  
  pl.default();
  pl.summary_function = @nanmean;
  pl.add_ribbon = true;
  pl.x = bint;
  pl.vertical_lines_at = 0;
  pl.shape = [3, 2];
  pl.order_panels_by = { 'mutual', 'm1' };
  pl.y_label = 'sp/s';
  
	clf( f );
  
  h = subset.plot( pl, 'kind', {'looks_by', 'looks_to', 'region', 'unit_id'} );  
  
  filename = strjoin( subset.flat_uniques({'region', 'looks_to', 'looks_by', 'unit_id'}), '_' );
  
  shared_utils.plot.save_fig( f, fullfile(save_plot_p, filename), {'epsc', 'png', 'fig'}, true );  
end

%%  per unit z

pl = ContainerPlotter();

date_dir = datestr( now, 'mmddyy' );

selectors = { '01162018', '01172018', 'm1', 'm2', 'mutual' };

plt = zpsth.only( selectors );

kind = 'per_unit_z';

save_plot_p = fullfile( conf.PATHS.data_root, 'plots', 'psth', date_dir, kind, psth_info_str );

shared_utils.io.require_dir( save_plot_p );

[I, C] = plt.get_indices( {'unit_id'} );

f = figure(1);

for i = 1:numel(I)
  fprintf( '\n %d of %d', i, numel(I) );
  
  subset = plt(I{i});
  
  pl.default();
  pl.summary_function = @nanmean;
  pl.x = bint;
  pl.vertical_lines_at = 0;
  pl.shape = [3, 2];
  pl.order_panels_by = { 'mutual', 'm1' };
  pl.y_label = 'z-scored firing rate';
  pl.add_ribbon = true;
  pl.add_legend = false;
  
  clf( f );
  
  h = subset.plot( pl, 'looks_to', {'looks_by', 'looks_to', 'region', 'unit_id'} );  
%   
%   f_ = FigureEdits( f );
%   f_.one_legend();
  
  filename = strjoin( subset.flat_uniques({'region', 'looks_to', 'looks_by', 'unit_id'}), '_' );
  
  shared_utils.plot.save_fig( f, fullfile(save_plot_p, filename), {'epsc', 'png', 'fig'}, true );
  
end

%%  per unit, overlay rasters

pl = ContainerPlotter();

n_event_thresh = 10;

date_dir = datestr( now, 'mmddyy' );

% plt = psth({'01162018', '01172018', 'm1', 'm2', 'mutual'});
% plt = psth({'m1', 'm2', 'mutual'});
plt = psth({ 'mutual', 'm1', 'm2'} );
plt = plt.rm( 'unit_uuid__NaN' );

% plt = psth({'m1', 'eyes', 'unit_uuid__101'});

kind = 'per_unit_rasters_300_500';

save_plot_p = fullfile( conf.PATHS.data_root, 'plots', 'psth', date_dir, kind, psth_info_str );

shared_utils.io.require_dir( save_plot_p );

figs_are = { 'unit_uuid', 'looks_to', 'looks_by', 'region', 'look_order' };
title_is = union( figs_are, {'unit_uuid', 'unit_rating'} );

[I, C] = plt.get_indices( figs_are );

fig = figure(1);

for i = 1:numel(I)
  fprintf( '\n %d of %d', i, numel(I) );
  
  subset = plt(I{i});
  
  pl.default();
  pl.x = bint;
  pl.vertical_lines_at = 0;
  pl.order_panels_by = { 'mutual', 'm1' };
  pl.add_ribbon = true;
  pl.add_legend = false;
  pl.x_lim = [-0.3, 0.5];
  
  clf( fig );
  
  matching_raster = raster(C(i, :));
  
  if ( shape(matching_raster, 1) < n_event_thresh || ...
      ~any(sum(any(matching_raster.data, 2)) >= n_event_thresh) )
    continue;
  end
  
%   h = subset.plot( pl, 'looks_to', {'looks_by', 'looks_to', 'region', 'unit_uuid', 'unit_rating'} );
% 
  title_str = strjoin( flat_uniques(subset, title_is), ' | ' );
  meaned_data = nanmean( subset.data, 1 );
  err_data = ContainerPlotter.sem_1d( subset.data );
  
  smooth_amt = 7;
  
  meaned_data = smooth( meaned_data, smooth_amt );
  err_data = smooth( err_data, smooth_amt );
  
  hold off;
  plot( bint, meaned_data, 'b', 'linewidth', 2 ); hold on;
  
  xlim( [-0.3, 0.5] );
  
%   plot( bint, meaned_data+err_data, 'b' );
%   plot( bint, meaned_data-err_data, 'b' );
  
  title( title_str );
  
  y_lims = get( gca, 'ylim' );
  x_lims = get( gca, 'xlim' );
  
  
  offset_y = (y_lims(2) - y_lims(1)) / 5;
  y_lims = [y_lims(1) - offset_y, y_lims(2) + offset_y ];
  set( gca, 'ylim', y_lims );
  
   plot( [0; 0], y_lims, 'k' );
  
  min_x_lim = x_lims(1);
  max_x_lim = x_lims(2);
  max_y_lim = y_lims(2);
  min_y_lim = y_lims(1);
  
  min_y_lim = max_y_lim - (max_y_lim - min_y_lim) / 8;
  
  raster_data = matching_raster.data;
  
  raster_data = raster_data(:, raster_t >= -0.3);
  
  for j = 1:size(raster_data, 1)
    for k = 1:size(raster_data, 2)
      perc_y = (j-1) / size(raster_data, 1);
      perc_x = (k-1) / size(raster_data, 2);
      x_coord = ((max_x_lim - min_x_lim) * perc_x) + min_x_lim;
      y_coord = ((max_y_lim - min_y_lim) * perc_y) + min_y_lim;
      if ( raster_data(j, k) )
        hold on;
        plot( x_coord, y_coord, 'k*', 'markersize', 0.2 );
      end
    end
  end
  
  filename = strjoin( subset.flat_uniques(figs_are), '_' );
  
  shared_utils.plot.save_fig( gcf, fullfile(save_plot_p, filename), {'png', 'epsc', 'fig'}, true );
  
end