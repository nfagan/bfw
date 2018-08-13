spike_mats = bfw.require_intermediate_mats( [], bfw.get_intermediate_directory( 'spikes' ), [] );

all_units = Container();

for i = 1:numel(spike_mats)
  
  spikes = shared_utils.io.fload( spike_mats{i} );
  
  if ( spikes.is_link ), continue; end;
  
  un_filename = spikes.unified_filename;
  un_file = shared_utils.io.fload( fullfile(bfw.get_intermediate_directory('unified'), un_filename) );
  session = un_file.m1.mat_directory_name;
  
  units = spikes.data;
  
  labs = arrayfun( @(x) bfw.get_unit_labels(x, 'session_name', session, 'unified_filename', un_filename) ...
    , units, 'un', false );
  
  rebuilt = SparseLabels();
  
  for j = 1:numel(labs)
    rebuilt = append( rebuilt, labs{j} );
  end
  
  spike_data = arrayfun( @(x) x.times, units, 'un', false );
  
  all_units = all_units.append( Container(spike_data(:), rebuilt) );
end

%%

sync_mats = bfw.require_intermediate_mats( [], bfw.get_intermediate_directory('sync'), [] );

session_start_end_times = Container();

for i = 1:numel(sync_mats)
  sync_file = shared_utils.io.fload( sync_mats{i} );
  sync_col = strcmp( sync_file.sync_key, 'plex' );
  start_time_plex = sync_file.plex_sync(1, sync_col);
  stop_time_plex = sync_file.plex_sync(end, sync_col);
  un_filename = sync_file.unified_filename;
  un_file = shared_utils.io.fload( fullfile(bfw.get_intermediate_directory('unified'), un_filename) );
  session = un_file.m1.mat_directory_name;
  
  session_start_end_times = append( session_start_end_times ...
    , Container([start_time_plex, stop_time_plex] ...
    , 'session_name', session ...
    , 'unified_filename', un_filename) ...
    );
end

%%

[I, C] = session_start_end_times.get_indices( {'session_name', 'unified_filename'} );

per_session_data = Container();

for i = 1:numel(I)
  fprintf( '\n %d of %d', i, numel(I) );
  
  matching_spikes = all_units(C(i, 1));
  matching_start_stop = session_start_end_times(C(i, :));
  
  assert( shape(matching_start_stop, 1) == 1 );
  
  start_time = matching_start_stop.data(1);
  end_time = matching_start_stop.data(2);
  
  units = matching_spikes.data;
  
  for j = 1:numel(units)    
    unit = units{j};
    
    ts = unit >= start_time & unit <= end_time;
    
    unit = unit(ts);
    
    labs = one( matching_spikes.labels.numeric_index(j) );
    labs = labs.set_category( 'unified_filename', C{i, 2} );
    
    cont = Container( {unit(:)}, labs );
    
    per_session_data = append( per_session_data, cont );
  end
end

%%

inter_spike_data = cellfun( @(x) diff(x), per_session_data.data, 'un', false );
inter_spike = set_data( per_session_data, inter_spike_data );


%%
conf = bfw.config.load();

save_p = fullfile( conf.PATHS.plots, 'isi' );
save_p = fullfile( save_p, datestr(now, 'mmddyy') );

shared_utils.io.require_dir( save_p );

to_interval = inter_spike.rm( 'unit_uuid__NaN' );

plots_each = { 'region', 'unit_uuid', 'channel', 'session_name'};

[I, C] = to_interval.get_indices( plots_each );

f = figure(1);

pl = ContainerPlotter();

for i = 1:numel(I)
  fprintf( '\n %d of %d', i, numel(I) );
  
  clf( f ); 
  colormap( 'default' );
  
  subset = to_interval(I{i});
  subset_data = subset.data;
  
  rebuilt = Container();
  
  for j = 1:shape(subset, 1)
    if ( isempty(subset.data{j}) ), continue; end
    rebuilt = append( rebuilt, Container(subset.data{j}, subset.labels.numeric_index(j)) );
  end
  
  if ( isempty(rebuilt) ), continue; end
  
  un_filenames = rebuilt('unified_filename');
  session_name = char( rebuilt('session_name') );
  
  un_filenumbers = zeros( size(un_filenames) );
  
  for j = 1:numel(un_filenames)
    ind = numel(session_name) + 1 + numel('position_');
    substr = un_filenames{j}(ind+1:end);
    ind2 = strfind( substr, '.mat' );
    un_filenumber = str2double( substr(1:ind2-1) );
    assert( ~isnan(un_filenumber) );
    un_filenumbers(j) = un_filenumber;
  end
  
  [~, sindex] = sort( un_filenumbers );
  
  un_filenames = un_filenames(sindex);
  
  pl.default();
  pl.order_by = un_filenames;
  pl.y_label = 'mean inter-spike-interval (s)';
  
  h = pl.bar( rebuilt, 'unified_filename', 'session_name', {'unit_uuid', 'region', 'unit_rating'} );
  bars = findobj( h, 'type', 'bar' );
  hold on;
  lims = get( gca, 'ylim' );
  xlims = get( gca, 'xlim' );
  
  for j = 1:numel(un_filenames)
    subset_unfile = rebuilt(un_filenames(j));
    n = shape(subset_unfile, 1);
    txt = sprintf( 'N = %d', n );
    text( j - 0.25, bars(1).YData(j)+(lims(2)-lims(1))/15, txt );
  end
  
  session_mean = rowops.nanmean( rebuilt.data );
  session_dev = rowops.nanstd( rebuilt.data );
  plt_devs = [0.25, 0.5, 1, 2, 4, 8];
  
  hold on;
  plt_means = [ session_mean, session_mean ];
  plot( xlims, plt_means, 'k--' );
  text( xlims(2), plt_means(1), sprintf( 'Mean' ) );
  
  for j = 1:numel(plt_devs)
    ys = plt_means + (session_dev * plt_devs(j));
    
    if ( ys > lims(2) ), continue; end;
    
    plot( xlims, ys, 'k --' );
    text( xlims(2), ys(1), sprintf( '%0.2f SD', plt_devs(j)) );
  end
  
  filename = strjoin( flat_uniques(rebuilt, plots_each), '_' );
  
  full_filename = fullfile( save_p, filename );
  
  shared_utils.plot.save_fig( gcf(), full_filename, {'epsc', 'png', 'fig'}, true );
end





