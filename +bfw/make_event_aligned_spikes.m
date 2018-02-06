function make_event_aligned_spikes(varargin)

import shared_utils.io.fload;

defaults = bfw.get_common_make_defaults();
defaults.look_back = -0.5;
defaults.look_ahead = 0.5;
defaults.psth_bin_size = 0.05;
defaults.raster_fs = 1e3;

defaults.compute_null = true;
defaults.null_fs = 40e3;
defaults.null_n_iterations = 1e3;

params = bfw.parsestruct( defaults, varargin );

event_p = bfw.get_intermediate_directory( 'events' );
unified_p = bfw.get_intermediate_directory( 'unified' );
sync_p = bfw.get_intermediate_directory( 'sync' );
spike_p = bfw.get_intermediate_directory( 'spikes' );

spike_save_p = bfw.get_intermediate_directory( 'event_aligned_spikes' );

event_files = bfw.require_intermediate_mats( params.files, event_p, params.files_containing );

look_back = params.look_back;
look_ahead = params.look_ahead;
psth_bin_size = params.psth_bin_size;

raster_fs = params.raster_fs;

compute_null = params.compute_null;

null_fs = params.null_fs;
null_n_iterations = params.null_n_iterations;

allow_overwrite = params.overwrite;

parfor i = 1:numel(event_files)
  fprintf( '\n %d of %d', i, numel(event_files) );
  
  events = fload( event_files{i} );
  unified = fload( fullfile(unified_p, events.unified_filename) );
  
  sync_file = fullfile( sync_p, events.unified_filename );
  spike_file = fullfile( spike_p, events.unified_filename );
  
  full_filename = fullfile( spike_save_p, events.unified_filename );
  
  if ( bfw.conditional_skip_file(full_filename, allow_overwrite) ), continue; end
  
  if ( exist(sync_file, 'file') == 0 || exist(spike_file, 'file') == 0 )
    fprintf( '\n Missing sync or spike file for "%s".', events.unified_filename );
    continue;
  end
  
  sync = fload( sync_file );
  spikes = fload( spike_file );
  
  if ( spikes.is_link )
    spikes = fload( fullfile(spike_p, spikes.data_file) );
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
  
  current_raster = Container();
  current_psth = Container();
  current_z_psth = Container();
  current_null_psth = Container();
  
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
    [psth, psth_t] = looplessPSTH( mat_spikes, event_times, look_back, look_ahead, psth_bin_size );
    
    %   raster
    [raster, raster_t] = bfw.make_raster( mat_spikes, event_times, look_back, look_ahead, raster_fs );
    
    %   null psth
    if ( compute_null )
      null_psth_ = bfw.generate_null_psth( mat_spikes, event_times ...
        , look_back, look_ahead, psth_bin_size, null_n_iterations, null_fs );
      null_mean = mean( null_psth_, 1 );
      null_dev = std( null_psth_, [], 1 );
      z_psth_ = (psth - null_mean) ./ null_dev;
    else
      z_psth_ = nan( 1, numel(psth_t) );
      null_mean = nan( size(z_psth_) ); 
    end
    
    psth_ = Container( psth, ...
        'channel', channel_str ...
      , 'region', region ...
      , 'unit_name', unit_name ...
      , 'looks_to', roi ...
      , 'looks_by', monk ...
      , 'unified_filename', unified_filename ...
      , 'session_name', mat_directory_name ...
      );
    
    current_psth = current_psth.append( psth_ );
    
    unqs = psth_.field_label_pairs();
    
    current_raster = current_raster.append( Container(raster, unqs{:}) );
    current_z_psth = current_z_psth.append( Container(z_psth_, unqs{:}) );
    current_null_psth = current_null_psth.append( Container(null_mean, unqs{:}) );
  end
  
  spike_struct = struct();
  spike_struct.raster = current_raster;
  spike_struct.zpsth = current_z_psth;
  spike_struct.psth = current_psth;
  spike_struct.null = current_null_psth;
  spike_struct.psth_t = psth_t;
  spike_struct.raster_t = raseter_t;
  spike_struct.unified_filename = unified_filename;
  spike_struct.params = params;
  
  shared_utils.io.require_dir( spike_save_p );
  
  do_save( full_filename, spike_struct );
end

end

function do_save( filename, variable )
save( filename, 'variable' );
end