import shared_utils.io.fload;

conf = bfw.config.load();

event_aligned_p = bfw.get_intermediate_directory( 'event_aligned_spikes' );
event_mats = shared_utils.io.find( event_aligned_p, '.mat' );

zpsth = Container();
psth = Container();
raster = Container();
null_psth = Container();

for i = 1:numel(event_mats)
  spikes = shared_utils.io.fload( event_mats{i} );
  
  if ( i == 1 )
    bint = spikes.psth_t;
  end
  
  psth = psth.append( spikes.psth );
  zpsth = zpsth.append( spikes.zpsth );
  raster = raster.append( spikes.raster );
  null_psth = null_psth.append( spikes.null );
end

[psth, ~, C] = bfw.add_unit_id( psth );

zpsth = zpsth.require_fields( 'unit_id' );
raster = raster.require_fields( 'unit_id' );
null_psth = null_psth.require_fields( 'unit_id' );

for i = 1:size(C, 1)
  ind_z = zpsth.where( C(i, :) );
  ind_r = raster.where( C(i, :) );
  ind_n = null_psth.where( C(i, :) );
  
  unit_id_str = sprintf( 'unit__%d', i );
  zpsth('unit_id', ind_z) = unit_id_str;
  raster('unit_id', ind_r) = unit_id_str;
  null_psth('unit_id', ind_n) = unit_id_str;
end

psth_info_str = sprintf( 'step_%d_ms', spikes.params.psth_bin_size * 1e3 );

%%  plot population response matrix

pre_bin_t = -0.2;
post_bin_t = 0.2;

use_z = true;

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

selectors = { '01162018', '01172018' };
plt = psth.only( selectors );

kind = 'per_unit';

save_plot_p = fullfile( conf.PATHS.data_root, 'plots', 'psth' );
save_plot_p = fullfile( save_plot_p, date_dir, kind );
save_plot_p = fullfile( save_plot_p, psth_info_str );

shared_utils.io.require_dir( save_plot_p );

[I, C] = plt.get_indices( {'unit_id'} );

f = figure(1);

for i = 1:numel(I)
  fprintf( '\n %d of %d', i, numel(I) );
  subset = plt(I{i});
  
  unqs = subset.flat_uniques();
  
  matching_null = null_psth.only( unqs );
  
  subset = subset.require_fields( 'kind' );
  matching_null = matching_null.require_fields( 'kind' );
  
  subset('kind') = 'real';
  matching_null('kind') = 'null';
  
  subset = subset.append( matching_null );
  
  pl.default();
  pl.summary_function = @nanmean;
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

selectors = { '01162018', '01172018' };

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

date_dir = datestr( now, 'mmddyy' );

plt = psth({'01162018', '01172018'});

kind = 'per_unit_rasters';

save_plot_p = fullfile( conf.PATHS.data_root, 'plots', 'psth', date_dir, kind, psth_info_str );

shared_utils.io.require_dir( save_plot_p );

[I, C] = plt.get_indices( {'unit_id', 'looks_to', 'looks_by', 'region'} );

fig = figure(1);

for i = 1:numel(I)
  fprintf( '\n %d of %d', i, numel(I) );
  
  subset = plt(I{i});
  
  pl.default();
  pl.x = bint;
  pl.vertical_lines_at = 0;
  pl.order_panels_by = { 'mutual', 'm1' };
  
  clf(fig);
  
  h = subset.plot( pl, 'looks_to', {'looks_by', 'looks_to', 'region', 'unit_id'} );
  matching_raster = rasters(C(i, :));
  
  y_lims = get( gca, 'ylim' );
  x_lims = get( gca, 'xlim' );
  
  min_x_lim = x_lims(1);
  max_x_lim = x_lims(2);
  max_y_lim = y_lims(2);
  min_y_lim = y_lims(1);
  
  min_y_lim = max_y_lim - (max_y_lim - min_y_lim) / 8;
  
  raster_data = matching_raster.data;
  
  for j = 1:size(raster_data, 1)
    for k = 1:size(raster_data, 2)
      perc_y = (j-1) / size(raster_data, 1);
      perc_x = (k-1) / size(raster_data, 2);
      x_coord = ((max_x_lim - min_x_lim) * perc_x) + min_x_lim;
      y_coord = ((max_y_lim - min_y_lim) * perc_y) + min_y_lim;
      if ( raster_data(j, k) )
        hold on;
        plot( x_coord, y_coord, 'k*', 'markersize', 1 );
      end
    end
  end
  
  filename = strjoin( subset.flat_uniques({'region', 'looks_to', 'looks_by', 'unit_id'}), '_' );
  
  shared_utils.plot.save_fig( gcf, fullfile(save_plot_p, filename), {'png', 'epsc', 'fig'}, true );
  
end