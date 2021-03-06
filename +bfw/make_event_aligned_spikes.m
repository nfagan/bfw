function make_event_aligned_spikes(varargin)

import shared_utils.io.fload;

defaults = bfw.get_common_make_defaults();
defaults.look_back = -0.5;
defaults.look_ahead = 0.5;
defaults.psth_bin_size = 0.05;
defaults.raster_fs = 1e3;
defaults.per_event_psth = true;

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
  
  if ( events.adjustments.isKey('to_plex_time') )
    fprintf( ['\n Warning: This function expects events to be in .mat time,' ...
      , ' but they are in plexon time.'] );
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
  
  psth_t = NaN;
  raster_t = NaN;
  
  current_raster = Container();
  current_psth = Container();
  current_z_psth = Container();
  current_null_psth = Container();
  current_psth_event_ids = Container();
  
  for j = 1:N
    fprintf( '\n\t %d of %d', j, N );
    
    roi = C{j, 1};
    monk = C{j, 2};
    unit_index = C{j, 3};
    
    row = events.roi_key(roi);
    col = events.monk_key(monk);
    
    unit = spikes.data(unit_index);
    
    unit_start = -1;
    unit_stop = -1;
    unit_rating = NaN;
    unit_uuid = NaN;
    unit_name = 'name__undefined';
    
    if ( isfield(unit, 'start') )
      unit_start = unit.start;
    end
    if ( isfield(unit, 'stop') )
      unit_stop = unit.stop;
    end
    if ( isfield(unit, 'rating') )
      unit_rating = unit.rating;
    end
    if ( isfield(unit, 'uuid') )
      unit_uuid = unit.uuid;
    end
    if ( isfield(unit, 'name') )
      unit_name = unit.name;
    end
    
    spike_times = unit.times;
    channel_str = unit.channel_str;
    region = unit.region;
    unified_filename = spikes.unified_filename;
    mat_directory_name = unified.m1.mat_directory_name;
    
    event_times = events.times{row, col};
    event_ids = events.identifiers{row, col};
    looked_first_indices = events.looked_first_indices{row, 1};
    
    if ( isempty(event_times) || isempty(spike_times) ), continue; end
    
    if ( unit_start == -1 ), unit_start = spike_times(1); end
    if ( unit_stop == -1 ), unit_stop = spike_times(end); end
    
    within_time_bounds = spike_times >= unit_start & spike_times <= unit_stop;
    
    spike_times = spike_times(within_time_bounds);
    
    if ( isempty(spike_times) ), continue; end
    
    mat_spikes = bfw.clock_a_to_b( spike_times, clock_a, clock_b );
    
    %   discard events that occur before the first spike, or after the
    %   last spike
    in_bounds_evts = event_times >= mat_spikes(1) & event_times <= mat_spikes(end);
    
    event_times = event_times( in_bounds_evts );
    event_ids = event_ids( in_bounds_evts );
    
    if ( strcmp(monk, 'mutual') )
      looked_first_indices = looked_first_indices( in_bounds_evts );
    else
      looked_first_indices = NaN;
    end
    
    if ( isempty(event_times) ), continue; end
    
    in_bounds_spikes = mat_spikes > event_times(1) - look_back & mat_spikes < event_times(end) + look_ahead;
    mat_spikes = mat_spikes( in_bounds_spikes );
    
    if ( isempty(mat_spikes) ), continue; end
    
    %   actual spike measures -- psth
    if ( ~params.per_event_psth )
      [psth, psth_t] = looplessPSTH( mat_spikes, event_times, look_back, look_ahead, psth_bin_size );
      looked_first_indices = NaN;
    else
      for k = 1:numel(event_times)
        [c_psth, psth_t] = looplessPSTH( mat_spikes, event_times(k), look_back, look_ahead, psth_bin_size );
        if ( k == 1 )
          psth = zeros( numel(event_times), numel(psth_t) );
        end
        psth(k, :) = c_psth;
      end
    end
    
    %   raster
    [raster, raster_t] = bfw.make_raster( mat_spikes, event_times, look_back, look_ahead, raster_fs );
    
    %   null psth
    if ( compute_null )
      if ( ~params.per_event_psth )
        null_psth_ = bfw.generate_null_psth( mat_spikes, event_times ...
          , look_back, look_ahead, psth_bin_size, null_n_iterations, null_fs );
        null_mean = mean( null_psth_, 1 );
        null_dev = std( null_psth_, [], 1 );
        z_psth_ = (nanmean(psth) - null_mean) ./ null_dev;
      else
        z_psth_ = zeros( size(psth) );
        null_mean = zeros( size(psth) );
        for k = 1:numel(event_times)
          null_psth_ = bfw.generate_null_psth( mat_spikes, event_times(k) ...
            , look_back, look_ahead, psth_bin_size, null_n_iterations, null_fs );
          null_mean_ = nanmean( null_psth_, 1 );
          null_dev = nanstd( null_psth_, [], 1 );
          z_psth_(k, :) = (psth(k, :) - null_mean_) ./ null_dev;
          null_mean(k, :) = null_mean_;
        end
      end
    else
      z_psth_ = nan( size(psth) );
      null_mean = nan( size(z_psth_) ); 
    end
    
    psth_ = Container( psth, ...
        'channel', channel_str ...
      , 'region', region ...
      , 'unit_uuid', sprintf( 'unit_uuid__%d', unit_uuid ) ...
      , 'unit_rating', sprintf( 'unit_rating__%d', unit_rating ) ...
      , 'unit_name', unit_name ...
      , 'looks_to', roi ...
      , 'looks_by', monk ...
      , 'unified_filename', unified_filename ...
      , 'session_name', mat_directory_name ...
      );
    
    psth_ = psth_.require_fields( 'look_order' );
    
    %   add labels for which monkey looked first.
    
    looked_first_labels = cell( numel(looked_first_indices), 1 );
    
    for k = 1:numel(looked_first_indices)
      ind = looked_first_indices(k);
      if ( isnan(ind) )
        lab = 'look_order__NaN';
      elseif ( ind == 0 )
        lab = 'look_order__simultaneous';
      elseif ( ind == 1 )
        lab = 'look_order__m1';
      else
        assert( ind == 2, 'Unrecognized index %d".', ind )
        lab = 'look_order__m2';
      end
      looked_first_labels{k} = lab;
    end
    
    psth_( 'look_order' ) = looked_first_labels;
    
    current_psth = current_psth.append( psth_ );
    
    multi_trial_labels = psth_.labels;
    
    if ( ~params.per_event_psth )
      raster_and_evt_labels = multi_trial_labels.repeat( numel(event_ids) );
    else
      raster_and_evt_labels = multi_trial_labels;
    end
    
    current_raster = current_raster.append( Container(raster, raster_and_evt_labels) );
    current_z_psth = current_z_psth.append( Container(z_psth_, multi_trial_labels) );
    current_null_psth = current_null_psth.append( Container(null_mean, multi_trial_labels) );
    current_psth_event_ids = current_psth_event_ids.append( Container(event_ids(:), raster_and_evt_labels) );
  end
  
  spike_struct = struct();
  spike_struct.raster = current_raster;
  spike_struct.zpsth = current_z_psth;
  spike_struct.psth = current_psth;
  spike_struct.null = current_null_psth;
  spike_struct.psth_event_ids = current_psth_event_ids;
  spike_struct.psth_t = psth_t;
  spike_struct.raster_t = raster_t;
  spike_struct.unified_filename = unified_filename;
  spike_struct.params = params;
  
  shared_utils.io.require_dir( spike_save_p );
  
  do_save( full_filename, spike_struct );
end

end

function do_save( filename, variable )
save( filename, 'variable' );
end