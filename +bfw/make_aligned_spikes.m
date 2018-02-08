function make_aligned_spikes(varargin)

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

look_back = params.look_back;
look_ahead = params.look_ahead;
psth_bin_size = params.psth_bin_size;

raster_fs = params.raster_fs;

spike_p = bfw.get_intermediate_directory( 'spikes' );
event_p = bfw.get_intermediate_directory( 'events_per_day' );
unified_p = bfw.get_intermediate_directory( 'unified' );
output_p = bfw.get_intermediate_directory( 'event_aligned_spikes' );

event_files = bfw.require_intermediate_mats( params.files, event_p, params.files_containing );

session_map = containers.Map();

for i = 1:numel(event_files)
  events = fload( event_files{i} );
  un_filename = events.unified_filename;
  
  output_file = fullfile( output_p, un_filename );
  
  if ( bfw.conditional_skip_file(output_file, params.overwrite) )
    continue; 
  end
  
  unified = fload( fullfile(unified_p, un_filename) );
  
  if ( events.is_link )
    events = fload( fullfile(event_p, events.data_file) );
  end
  
  spike_file = fullfile( spike_p, un_filename );
  
  if ( ~shared_utils.io.fexists(spike_file) )
    fprintf( '\n Spike file for "%s" does not exist.', un_filename );
    continue;
  end
  
  spikes = fload( spike_file );
  
  if ( spikes.is_link )
    spikes = fload( fullfile(spike_p, spikes.data_file) );
  end
  
  event_info = events.event_info;
  event_times = event_info.data(:, events.event_info_key('times'));
  
  units = spikes.data;
  
  if ( numel(units) == 0 ), continue; end
  
  unit_inds = arrayfun( @(x) x, 1:numel(units), 'un', false );
  event_inds = arrayfun( @(x) x, 1:numel(event_times), 'un', false );
  all_inds = bfw.allcomb( {unit_inds, event_inds} );
  
  eg_labels = bfw.get_unit_labels( units(1) );
  
  new_cats = setdiff( eg_labels.categories(), event_info.categories() );
  event_info = event_info.require_fields( new_cats );
  
  unit_labs = cell( 1, numel(units) );
  unit_labs{1} = eg_labels;
  
  for j = 2:numel(units)
    unit_labs{j} = bfw.get_unit_labels( units(j) );
  end
  
  conts = cell( size(all_inds, 1), 1 );
  
  for j = 1:size(all_inds, 1)
    unit_ind = all_inds{j, 1};
    event_ind = all_inds{j, 2};
    
    unit = units(unit_ind);
    event = event_times(event_ind);
    
    [c_psth, psth_t] = looplessPSTH( unit.times, event, look_back, look_ahead, psth_bin_size );
    [c_raster, raster_t] = bfw.make_raster( unit.times, event, look_back, look_ahead, raster_fs );
    
    if ( j == 1 )
      psth_matrix = zeros( size(all_inds, 1), numel(psth_t) );
      raster_matrix = zeros( size(all_inds, 1), numel(raster_t) );
    end
    
    conts{j} = unit_labs{unit_ind};
    
    psth_matrix(j, :) = c_psth;
    raster_matrix(j, :) = c_raster;
  end
  
  event_inds = all_inds(:, 2);
  event_inds = [ event_inds{:} ];
  unit_inds = all_inds(:, 1);
  unit_inds = [ unit_inds{:} ];
  u_unit_inds = unique( unit_inds );
  
  event_info = event_info(event_inds);
  psth_cont = set_data( event_info, psth_matrix );
  
  d = 10;  

end

end

function one_session( events, params )

import shared_utils.io.fload;

if ( numel(events) == 0 ), return; end

spike_p = bfw.get_intermediate_directory( 'spikes' );
unified_p = bfw.get_intermediate_directory( 'unified' );
spike_save_p = bfw.get_intermediate_directory( 'event_aligned_spikes' );

look_back = params.look_back;
look_ahead = params.look_ahead;
psth_bin_size = params.psth_bin_size;

raster_fs = params.raster_fs;

compute_null = params.compute_null;

null_fs = params.null_fs;
null_n_iterations = params.null_n_iterations;

allow_overwrite = params.overwrite;

event_info = Container();

event_info_keys = { 'times', 'durations', 'lengths', 'ids', 'looked_first' };
event_info_vals = 1:numel(event_info_keys);
event_info_key = containers.Map( event_info_keys, event_info_vals );

for i = 1:numel(events)
  evt = events(i);
  
  rois = evt.roi_key.keys();
  monks = evt.monk_key.keys();
  
  unified_filename = evt.unified_filename;
  unified = fload( fullfile(unified_p, unified_filename) );
  
  mat_directory_name = unified.m1.mat_directory_name;
  
  for j = 1:numel(rois)
    roi = rois{j};
    row = evt.roi_key(roi);
    
    for k = 1:numel(monks)
      monk = monks{k};
      col = evt.monk_key(monk);
      
      c_evt_times = evt.times{row, col};
      c_durations = evt.durations{row, col};
      c_lengths = evt.lengths{row, col};
      c_ids = double( evt.identifiers{row, col} );
      c_looked_first = nan( size(c_ids) );
      
      if ( strcmp(monk, 'mutual') )
        c_looked_first = evt.looked_first_indices{row, 1};
      end
      
      look_orders = cell( numel(c_looked_first), 1 );
      
      for h = 1:numel(c_looked_first)
        look_order = c_looked_first(h);
        
        if ( isnan(look_order) )
          lo = 'NaN';
        elseif ( look_order == 0 )
          lo = 'simultaneous';
        elseif ( look_order == 1 )
          lo = 'm1';
        else
          assert( look_order == 2, 'Unrecognized look order %d.', look_order );
          lo = 'm2';
        end        
        
        look_orders{h} = sprintf( 'look_order__%s', lo );
      end
      
      labs = SparseLabels.create( ...
          'unified_filename', unified_filename ...
        , 'session_name', mat_directory_name ...
        , 'looks_to', roi ...
        , 'looks_by', monk ...
        , 'look_order', look_orders ...
      );
    
      data = [ c_evt_times(:), c_durations(:), c_lengths(:), c_ids(:), c_looked_first(:) ];
    
      event_info = append( event_info, Container(data, labs) );
    end
  end
end

unified_filename = events(1).unified_filename;
spike_file = fullfile( spike_p, unified_filename );

if ( ~shared_utils.io.fexists(spike_file) )
  fprintf( '\n Missing spike file for "%s".', unified_filename );
  return
end

spikes = fload( spike_file );

if ( spikes.is_link )
  spikes = fload( fullfile(spike_p, spikes.data_file) );
  unified_filename = spikes.unified_filename;
end

full_filename = fullfile( spike_save_p, unified_filename );

if ( bfw.conditional_skip_file(full_filename, allow_overwrite) ), return; end

units = spikes.data;

[I, C] = event_info.get_indices( {'looks_to', 'looks_by'} );

psth = Container();
null_psth = Container();
zpsth = Container();
rasters = Container();
rebuilt_event_info = Container();

unit_indices = arrayfun( @(x) x, 1:numel(units), 'un', false );
event_info_indices = arrayfun( @(x) x, 1:numel(I), 'un', false );

all_indices = bfw.allcomb( {unit_indices, event_info_indices} );

for i = 1:size(all_indices, 1)
  unit_index = all_indices{i, 1};
  event_info_index = all_indices{i, 2};

  unit = units(unit_index);
  spike_ts = unit.times;
  
  unit_rating = NaN;
  unit_uuid = NaN;
  unit_name = 'name__undefined';

  if ( isfield(unit, 'rating') )
    unit_rating = unit.rating;
  end
  if ( isfield(unit, 'uuid') )
    unit_uuid = unit.uuid;
  end
  if ( isfield(unit, 'name') )
    unit_name = unit.name;
  end

  channel_str = unit.channel_str;
  region = unit.region;
  
  subset_evts = event_info(I{event_info_index});

  event_times = subset_evts.data(:, event_info_key('times'));

  min_evt = min( event_times );
  max_evt = max( event_times );

  c_spike_ts = spike_ts;
  c_spike_ts = c_spike_ts( c_spike_ts >= min_evt + look_back & ...
    c_spike_ts <= max_evt + look_ahead );

  %   real psth, per event
  for h = 1:numel(event_times)
    [c_psth, psth_t] = looplessPSTH( c_spike_ts, event_times(h) ...
      , look_back, look_ahead, psth_bin_size );
    if ( h == 1 )
      psth_data = zeros( numel(event_times), numel(psth_t) );
    end
    psth_data(h, :) = c_psth;
  end

  %   null psth, per event
  if ( compute_null )
    n_psth_data = bfw.generate_null_psth( c_spike_ts, event_times ...
      , look_back, look_ahead, psth_bin_size, null_n_iterations, null_fs );
    null_mean = mean( n_psth_data, 1 );
    null_dev = std( n_psth_data, [], 1 );
    z_psth_data = (nanmean(psth_data) - null_mean) ./ null_dev;
  else
    n_psth_data = nan( 1, numel(psth_t) );
    z_psth_data = nan( 1, numel(psth_t) );
  end

  [raster, raster_t] = bfw.make_raster( c_spike_ts, event_times, look_back, look_ahead, raster_fs );

  subset_evts = subset_evts.require_fields( {'channel', 'region' ...
    , 'unit_uuid', 'unit_rating', 'unit_name'} );

  subset_evts('channel') = channel_str;
  subset_evts('region') = region;
  subset_evts('unit_rating') = sprintf( 'unit_rating__%d', unit_rating );
  subset_evts('unit_uuid') = sprintf( 'unit_uuid__%d', unit_uuid );
  subset_evts('unit_name') = unit_name;

  psth = append( psth, set_data(subset_evts, psth_data) );
  null_psth = append( null_psth, set_data(one(subset_evts), n_psth_data) );
  zpsth = append( zpsth, set_data(one(subset_evts), z_psth_data) );
  rebuilt_event_info = append( rebuilt_event_info, subset_evts );
  rasters = append( rasters, set_data(subset_evts, raster) );
end

spike_struct = struct();
spike_struct.raster = rasters;
spike_struct.zpsth = zpsth;
spike_struct.psth = psth;
spike_struct.null = null_psth;
spike_struct.psth_t = psth_t;
spike_struct.raster_t = raster_t;
spike_struct.event_info = rebuilt_event_info;
spike_struct.event_info_key = event_info_key;
spike_struct.unified_filename = unified_filename;
spike_struct.params = params;

shared_utils.io.require_dir( spike_save_p );

do_save( full_filename, spike_struct );

end

function do_save( filename, variable )
save( filename, 'variable' );
end