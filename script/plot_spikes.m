import shared_utils.io.fload;

conf = bfw.config.load();

event_p = bfw.get_intermediate_directory( 'events' );
unified_p = bfw.get_intermediate_directory( 'unified' );
bounds_p = bfw.get_intermediate_directory( 'bounds' );
sync_p = bfw.get_intermediate_directory( 'sync' );
spike_p = bfw.get_intermediate_directory( 'spikes' );
event_files = shared_utils.io.find( event_p, '.mat' );

first_event_file = fload( event_files{1} );
first_bounds_file = fload( fullfile(bounds_p, first_event_file.unified_filename) );
first_event_params = first_event_file.params;

event_param_str = sprintf( 'event_%s_%d', first_event_params.mutual_method, first_event_params.duration );
window_param_str = sprintf( 'window_%d_step_%d', first_bounds_file.window_size, first_bounds_file.step_size );
event_subdir = sprintf( '%s_%s', event_param_str, window_param_str );

psth = Container();
z_psth = Container();
evt_info = Container();
all_event_lengths = Container();
all_event_distances = Container();
rasters = Container();

spike_map = containers.Map();

look_back = -0.5;
look_ahead = 0.5;
psth_bin_size = 0.01;

raster_fs = 1e3;

compute_null = true;
null_fs = 40e3;
null_n_iterations = 1e3;

for i = 1:numel(event_files)
  fprintf( '\n %d of %d', i, numel(event_files) );
  
  events = fload( event_files{i} );
  unified = fload( fullfile(unified_p, events.unified_filename) );
  plex_file = unified.m1.plex_filename;
  
  sync_file = fullfile( sync_p, events.unified_filename );
  spike_file = fullfile( spike_p, events.unified_filename );
  
  if ( exist(sync_file, 'file') == 0 || exist(spike_file, 'file') == 0 )
    fprintf( '\n Missing sync or spike file for "%s".', events.unified_filename );
    continue;
  end
  
  sync = fload( sync_file );
  spikes = fload( spike_file );
  
  if ( ~spikes.is_link )
    spike_map( plex_file ) = spikes;
  elseif ( ~spike_map.isKey(plex_file) )
    spikes = fload( fullfile(spike_p, spikes.data_file) );
    spike_map( plex_file ) = spikes;
  else
    spikes = spike_map( plex_file );
  end
  
  %   convert spike times in plexon time (a) to matlab time (b)
  clock_a = sync.plex_sync(:, strcmp(sync.sync_key, 'plex'));
  clock_b = sync.plex_sync(:, strcmp(sync.sync_key, 'mat'));
  
  rois = events.roi_key.keys();
  monks = events.monk_key.keys();
  unit_indices = arrayfun( @(x) x, 1:numel(spikes.data), 'un', false );
  
  C = bfw.allcomb( {rois, monks, unit_indices} );
  
  %   then get spike info
  
  N = size(C, 1);
  
  for j = 1:N
    fprintf( '\n\t %d of %d', j, N );
    
    roi = C{j, 1};
    monk = C{j, 2};
    unit_index = C{j, 3};
    
    row = events.roi_key(roi);
    col = events.monk_key(monk);
    
    unit = spikes.data(unit_index);
    
    unit_start = unit.start;
    unit_stop = unit.stop;
    spike_times = unit.times;
    channel_str = unit.channel_str;
    region = unit.region;
    unit_name = unit.name;
    unified_filename = spikes.unified_filename;
    mat_directory_name = unified.m1.mat_directory_name;    
    
    event_times = events.times{row, col};
    
    if ( isempty(event_times) || isempty(spike_times) ), continue; end
    
    if ( unit_start == -1 ), unit_start = spike_times(1); end
    if ( unit_stop == -1 ), unit_stop = spike_times(end); end
    
    within_time_bounds = spike_times >= unit_start & spike_times <= unit_stop;
    
    spike_times = spike_times(within_time_bounds);
    
    if ( isempty(spike_times) ), continue; end
    
    mat_spikes = bfw.clock_a_to_b( spike_times, clock_a, clock_b );
    
    %   discard events that occur before the first spike, or after the
    %   last spike
    event_times = event_times( event_times >= mat_spikes(1) & event_times <= mat_spikes(end) );
    
    if ( isempty(event_times) ), continue; end
    
    in_bounds_spikes = mat_spikes > event_times(1) - look_back & mat_spikes < event_times(end) + look_ahead;
    mat_spikes = mat_spikes( in_bounds_spikes );
    
    if ( isempty(mat_spikes) ), continue; end
    
    %   actual spike measures -- psth
    [psth_, bint] = looplessPSTH( mat_spikes, event_times, look_back, look_ahead, psth_bin_size );
    %   raster
    raster = bfw.make_raster( mat_spikes, event_times, look_back, look_ahead, raster_fs );
    %   null psth
    if ( compute_null )
      null_psth_ = bfw.generate_null_psth( mat_spikes, event_times ...
        , look_back, look_ahead, psth_bin_size, null_n_iterations, null_fs );
      null_mean = mean( null_psth_, 1 );
      null_dev = std( null_psth_, [], 1 );
      z_psth_ = (psth_ - null_mean) ./ null_dev;
    else
      z_psth_ = nan( 1, numel(bint) );
    end
    
    cont_ = Container( psth_, ...
        'channel', channel_str ...
      , 'region', region ...
      , 'unit_name', unit_name ...
      , 'looks_to', roi ...
      , 'looks_by', monk ...
      , 'unified_filename', unified_filename ...
      , 'session_name', mat_directory_name ...
      );
    
    psth = psth.append( cont_ );
    
    unqs = cont_.field_label_pairs();
    
    rasters = rasters.append( Container(raster, unqs{:}) );
    z_psth = z_psth.append( Container(z_psth_, unqs{:}) );
  end
end

[psth, ~, C] = bfw.add_unit_id( psth );

rasters = rasters.require_fields( 'unit_id' );
for i = 1:size(C, 1)
  ind = rasters.where(C(i, :));
  rasters('unit_id', ind) = sprintf( 'unit__%d', i );
end

z_psth = z_psth.require_fields( 'unit_id' );
for i = 1:size(C, 1)
  ind = z_psth.where(C(i, :));
  z_psth('unit_id', ind) = sprintf( 'unit__%d', i );
end

%%

event_aligned_p = bfw.get_intermediate_directory( 'event_aligned_spikes' );
event_mats = shared_utils.io.find( event_aligned_p, '.mat' );

zpsth = Container();
psth = Container();
raster = Container();

for i = 1:numel(event_mats)
  spikes = shared_utils.io.fload( event_mats{i} );
  
  if ( i == 1 )
    bint = spikes.psth_t;
  end
  
  psth = psth.append( spikes.psth );
  zpsth = zpsth.append( spikes.zpsth );
  raster = raster.append( spikes.raster );
end

[psth, ~, C] = bfw.add_unit_id( psth );

zpsth = zpsth.require_fields( 'unit_id' );
raster = raster.require_fields( 'unit_id' );

for i = 1:size(C, 1)
  ind_z = zpsth.where( C(i, :) );
  ind_r = raster.where( C(i, :) );
  zpsth('unit_id', ind_z) = sprintf( 'unit__%d', i );
  raster('unit_id', ind_r) = sprintf( 'unit__%d', i );
end

psth_info_str = sprintf( 'step_%d_ms', spikes.params.psth_bin_size * 1e3 );


%%  plot population response matrix

pre_bin_t = -0.2;
post_bin_t = 0.2;

pre_ind = bint >= pre_bin_t & bint < 0;
post_ind = bint > 0 & bint <= post_bin_t;

psth_pre = set_data( psth, nanmean(psth.data(:, pre_ind), 2) );
psth_post = set_data( psth, nanmean(psth.data(:, post_ind), 2) );

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
  subset_ = psth_modulation(I{i});
  
  regs = subset_('region');
  
  reg = char( regs );
  
  current_color = colors( reg );
  
%   if ( i == 1 ), legend( gca, '-dynamiclegend' ); end
  legend( '-dynamiclegend' );
  
  for j = 1:numel(regs)
    subset = subset_(regs(j));
    
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
    
    if ( ~legend_components.isKey(regs{j}) )
      legend_components(regs{j}) = h;
    end
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
fname = strjoin( res.flat_uniques({'session_name'}), '_' );
fname = sprintf( 'population_matrix_%s', fname );
date_dir = datestr( now, 'mmddyy' );
save_plot_p = fullfile( conf.PATHS.data_root, 'plots', 'population_response' );
save_plot_p = fullfile( save_plot_p, date_dir, kind, event_subdir );
shared_utils.io.require_dir( save_plot_p );

shared_utils.plot.save_fig( gcf, fullfile(save_plot_p, fname), {'epsc', 'png', 'fig'} );

%%  per unit

date_dir = datestr( now, 'mmddyy' );

% plt = cont({'01162018', '01172018'});
% plt = cont;
plt = zpsth({'01162018', '01172018'});

% plt = plt.replace( 'm1', 'zm1' );
% plt = plt.replace( 'm2', 'zm2' );

kind = 'per_unit_z';

save_plot_p = fullfile( conf.PATHS.data_root, 'plots', 'psth' );
save_plot_p = fullfile( save_plot_p, date_dir, kind );
save_plot_p = fullfile( save_plot_p, event_subdir );

shared_utils.io.require_dir( save_plot_p );

[I, C] = plt.get_indices( {'unit_id'} );

for i = 1:numel(I)
  subset = plt(I{i});
  
  pl.default();
  pl.summary_function = @nanmean;
  pl.x = bint;
  pl.vertical_lines_at = 0;
  pl.shape = [3, 2];
  pl.order_panels_by = { 'mutual', 'm1' };
  
  figure(1); clf();
  
%   subset.plot( pl, 'looks_to', {'looks_by', 'region', 'unit_id'} );
  h = subset.plot( pl, 'looks_to', {'looks_by', 'looks_to', 'region', 'unit_id'} );
  
  matching_raster = rasters(C(i, :));
  
  
  filename = strjoin( subset.flat_uniques({'region', 'looks_to', 'looks_by', 'unit_id'}), '_' );
  
  saveas( gcf, fullfile(save_plot_p, [filename, '.eps']) );
  saveas( gcf, fullfile(save_plot_p, [filename, '.png']) );
  
end

%%  per unit, overlay rasters

pl = ContainerPlotter();

date_dir = datestr( now, 'mmddyy' );

% plt = cont({'01162018', '01172018'});
% plt = cont;
plt = psth({'01162018', '01172018'});
plt = plt({'m1_leads_m2','m2_leads_m1'});

% plt = plt.replace( 'm1', 'zm1' );
% plt = plt.replace( 'm2', 'zm2' );

kind = 'per_unit_rasters';

save_plot_p = fullfile( conf.PATHS.data_root, 'plots', 'psth' );
save_plot_p = fullfile( save_plot_p, date_dir, kind, event_subdir );

shared_utils.io.require_dir( save_plot_p );

[I, C] = plt.get_indices( {'unit_id', 'looks_to', 'looks_by', 'region'} );

fig = figure(1);

for i = 1:numel(I)
  fprintf( '\n %d of %d', i, numel(I) );
  
  subset = plt(I{i});
  
  pl.default();
  pl.x = bint;
  pl.vertical_lines_at = 0;
%   pl.shape = [3, 2];
  pl.order_panels_by = { 'mutual', 'm1' };
  
  clf(fig);
  
%   subset.plot( pl, 'looks_to', {'looks_by', 'region', 'unit_id'} );
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