import shared_utils.io.fload;

conf = bfw.config.load();

% event_aligned_p = bfw.get_intermediate_directory( 'event_aligned_spikes' );
event_aligned_p = bfw.get_intermediate_directory( 'modulation_type' );
event_spike_p = bfw.get_intermediate_directory( 'event_aligned_spikes' );
event_mats = shared_utils.io.find( event_aligned_p, '.mat' );

zpsth = Container();
psth = Container();
raster = Container();
null_psth = Container();
full_psth = Container();

got_bin_t = false;

for i = 1:numel(event_mats)
  fprintf( '\n %d of %d', i, numel(event_mats) );
  
  spikes = shared_utils.io.fload( event_mats{i} );
  
  if ( isfield(spikes, 'is_link') && spikes.is_link ), continue; end
  
  c_full_psth = shared_utils.io.fload( fullfile(event_spike_p, spikes.unified_filename) );
  
  if ( isfield(c_full_psth, 'is_link') && c_full_psth.is_link )
    c_full_psth = shared_utils.io.fload( fullfile(event_spike_p, c_full_psth.data_file) );
  end
  if ( ~full_psth.contains(spikes.psth('session_name')) )
    full_psth = full_psth.append( c_full_psth.psth );
  end
  
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
% plt = psth({ 'mutual', 'm1', 'm2'} );
% plt = plt.rm( 'unit_uuid__NaN' );
% plt = plt({'m1', 'm2'});

plt = psth({'unit_uuid__1555', 'm1', 'mutual', 'eyes', 'face'});

% plt = psth({'m1', 'eyes', 'unit_uuid__101'});

kind = 'per_unit_rasters';

save_plot_p = fullfile( conf.PATHS.data_root, 'plots', 'psth', date_dir, kind, psth_info_str );

shared_utils.io.require_dir( save_plot_p );

figs_are = { 'unit_uuid', 'looks_to', 'looks_by', 'region' };
title_is = union( figs_are, {'unit_uuid', 'unit_rating'} );

[I, C] = plt.get_indices( figs_are );

fig = figure(1);

figs = gobjects(1, 4);

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
  
  fig = figure(i);
  
  figs(i) = fig;
  
  clf( fig );
  
  matching_raster = raster(C(i, :));
  
  if ( shape(matching_raster, 1) < n_event_thresh )
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
  
  min_y_lim = max_y_lim - (max_y_lim - min_y_lim) / 1;
  
  raster_data = matching_raster.data;
  
  raster_data = raster_data(:, raster_t >= -0.3);
  
  [row, col] = find( raster_data );
  
  total_events_per_row = sum( raster_data, 2 );
  
  perc_y = row ./ size(raster_data, 1);
  perc_x = col ./ size(raster_data, 2);
  
  x_coords = (max_x_lim - min_x_lim) .* perc_x + min_x_lim;
  y_coords = (max_y_lim - min_y_lim) .* perc_y + min_y_lim;
  
  scatter( x_coords, y_coords, 0.2 );
  
  for j = 1:numel(total_events_per_row)
    text( 0.5, y_coords(j), sprintf('%d', total_events_per_row(j)), 'parent', gca );
  end
  
%   for j = 1:size(raster_data, 1)
%     for k = 1:size(raster_data, 2)
%       perc_y = (j-1) / size(raster_data, 1);
%       perc_x = (k-1) / size(raster_data, 2);
%       x_coord = ((max_x_lim - min_x_lim) * perc_x) + min_x_lim;
%       y_coord = ((max_y_lim - min_y_lim) * perc_y) + min_y_lim;
%       if ( raster_data(j, k) )
%         hold on;
%         plot( x_coord, y_coord, 'k*', 'markersize', 0.2 );
%       end
%     end
%   end
  
  filename = strjoin( subset.flat_uniques(figs_are), '_' );
  
%   shared_utils.plot.save_fig( gcf, fullfile(save_plot_p, filename), {'png', 'epsc', 'fig'}, true );
  
end

%%

pl = ContainerPlotter();

selectors = {'unit_uuid__1555', 'm1', 'mutual', 'eyes', 'face'};

plot_null = false;
plot_err = true;

% plt = psth(selectors);
plt = full_psth(selectors);

figs_are = { 'unit_uuid', 'looks_to', 'looks_by', 'region' };
title_is = union( figs_are, {'unit_uuid', 'unit_rating'} );

[I, C] = plt.get_indices( figs_are );

fig = figure(1);
clf( fig );

subplot(2, 4, 1);

stp = 1;

for i = 1:numel(I)
  fprintf( '\n %d of %d', i, numel(I) );
  
  subset = plt(I{i});
  subset_null = null_psth(C(i, :));
  
  assert( shape(subset_null, 1) == 1 );
  
  smooth_amt = 7;
  meaned_data = smooth( nanmean(subset.data, 1), smooth_amt );
  meaned_data = meaned_data(:)';
  
  smoothed_err = smooth( rowops.sem(subset.data), smooth_amt );
  smoothed_err = smoothed_err(:)';
  
  meaned_null = smooth( nanmean(subset_null.data, 1), smooth_amt );
  meaned_null = meaned_null(:)';
  
  ind = bint >= -0.3;
  
  subplot( 2, 4, stp );
  plot( bint(ind), meaned_data(:, ind), 'b', 'linewidth', 2 );
  
  if ( plot_null )
    hold on;
    plot( bint(ind), meaned_null(:, ind), 'r' );
  end
  if ( plot_err )
    hold on;
    plot( bint(ind), meaned_data(:, ind) + smoothed_err(:, ind), 'b' );
    plot( bint(ind), meaned_data(:, ind) - smoothed_err(:, ind), 'b' );
  end
  
  xlim( [-0.3, 0.5] );
  ylim( [0, 50] );
  
  title( strjoin(C(i, :), ' | ') );
  
  matching_raster = raster(C(i, :));
  raster_data = matching_raster.data;
  raster_data = raster_data(:, raster_t >= -0.3);
  
  subplot( 2, 4, stp + 1 ); hold on;
  for j = 1:size(raster_data, 1)
    inds = find( raster_data(j, :) );
    if ( isempty(inds) ), continue; end
    scatter( inds, repmat(j, 1, numel(inds)), 0.2, 'k' );
  end
  
  ylim( [0, 300] );
  
  title( strjoin(C(i, :), ' | ') );
  
  stp = stp + 2;
end

%%  plot two panels

kind = 'side_by_side_psth_raster';
save_plot_p = fullfile( conf.PATHS.data_root, 'plots', 'psth', date_dir, kind, psth_info_str );
shared_utils.io.require_dir( save_plot_p );

pl = ContainerPlotter();

sub_psth = psth({'m1', 'mutual', 'eyes', 'face'});
sub_psth = sub_psth.rm( 'unit_uuid__NaN' );

[all_i, all_c] = sub_psth.get_indices( {'unit_uuid', 'channel'} );

n_event_thresh = 10;

fig = figure(1);

for idx = 1:numel(all_i)
  fprintf( '\n %d of %d', idx, numel(all_i) );

  plot_null = false;
  plot_err = true;

  plt = sub_psth(all_i{idx});

  figs_are = { 'unit_uuid', 'looks_to', 'looks_by', 'region' };
  title_is = union( figs_are, {'unit_uuid', 'unit_rating'} );

  [I, C] = plt.get_indices( figs_are );

  clf( fig );

  subplot(1, 2, 1);

  cstp = 1;

  colors = containers.Map();
  colors('eyes, mutual') = [1, 0, 0];
  colors('eyes, m1') = [0.75, 0, 0];
  colors('face, mutual') = [0, 0.75, 0];
  colors('face, m1') = [0, 0.3, 0];

  current_max = 1;

  color_strs = cell( 1, numel(I) );

  h = gobjects( 1, numel(I) );
  
  should_save = true;
  
  t1 = tic();
  for i = 1:numel(I)
    if ( ~should_save ), continue; end

    color_str = strjoin( C(i, 2:3), ', ' );
    color_strs{i} = color_str;

    subset = plt(I{i});
    subset_null = null_psth(C(i, :));
    subset_null = subset_null.only( all_c{idx, 2} );

    assert( shape(subset_null, 1) == 1 );

    smooth_amt = 7;
    meaned_data = smooth( nanmean(subset.data, 1), smooth_amt );
    meaned_data = meaned_data(:)';

    smoothed_err = smooth( rowops.sem(subset.data), smooth_amt );
    smoothed_err = smoothed_err(:)';

    meaned_null = smooth( nanmean(subset_null.data, 1), smooth_amt );
    meaned_null = meaned_null(:)';

    ind = bint >= -0.3;

    subplot( 1, 2, 1 ); hold on;
    h(i) = plot( bint(ind), meaned_data(:, ind), 'k', 'linewidth', 2 );
    set( h(i), 'color', colors(color_str) );

    xlim( [-0.3, 0.5] );
    ylim( [0, 50] );
    
    hold on;
    plot( [0, 0], [0, 50], 'k--' );
    ylabel( 'spikes / second' );
    xlabel( 'time (s) from event onset' );

    title( strjoin(C(i, :), ' | ') );

    matching_raster = raster(C(i, :));
    raster_data = matching_raster.data;
    raster_data = raster_data(:, raster_t >= -0.3);
    c_raster_t = raster_t( raster_t >= -0.3 );
    
    if ( size(raster_data, 1) < n_event_thresh )
      should_save = false;
      continue;
    end
    
    inds = cell( 1, size(raster_data, 1) );
    ts = cell( 1, size(raster_data, 1) );
    cstp = 1;
    for j = 1:size(raster_data, 1)
      inds{j} = find( raster_data(j, :) );
      ts{j} = repmat( cstp, 1, numel(inds{j}) );
      if ( ~isempty(inds{j}) )
        cstp = cstp + 1;
      end
    end
    empties = cellfun( @isempty, inds );
    inds(empties) = [];
    ts(empties) = [];
    
    inds = [inds{:}];
    ts = [ts{:}];
    subplot( 1, 2, 2 ); hold on;
    
    current_n = sum( ~empties );
    scatter( c_raster_t(inds), current_max + ts - 1, 0.2, colors(color_str) );
    current_max = current_max + current_n;

    current_max = current_max + 20;

    ylim( [0, 1350] );
    xlim( [-0.3, 0.5] );
    
    hold on;
    plot( [0, 0], [0, 1350], 'k--' );
    xlabel( 'time (s) from event onset' );
    
  end
  toc(t1);

  legend( h, color_strs );
  
  if ( should_save )
    fname = strjoin( flat_uniques(plt, union(figs_are, 'channel')), '_' );
    full_fname = fullfile( save_plot_p, fname );
    t2 = tic();
    shared_utils.plot.save_fig( fig, full_fname, {'epsc', 'fig', 'png'}, true );      
    toc( t2 );
  end
end

