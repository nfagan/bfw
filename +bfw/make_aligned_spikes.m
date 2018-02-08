function make_aligned_spikes(varargin)

import shared_utils.io.fload;

defaults = bfw.get_common_make_defaults();
defaults.look_back = -0.5;
defaults.look_ahead = 0.5;
defaults.psth_bin_size = 0.01;
defaults.raster_fs = 1e3;
defaults.per_event_psth = true;

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

parfor i = 1:numel(event_files)
  events = fload( event_files{i} );
  un_filename = events.unified_filename;
  
  output_file = fullfile( output_p, un_filename );
  
  if ( bfw.conditional_skip_file(output_file, params.overwrite) )
    continue; 
  end
  
  unified = fload( fullfile(unified_p, un_filename) );
  
  spike_file = fullfile( spike_p, un_filename );
  
  if ( ~shared_utils.io.fexists(spike_file) )
    fprintf( '\n Spike file for "%s" does not exist.', un_filename );
    continue;
  end
  
  if ( events.is_link )
    spike_struct = struct();
    spike_struct.is_link = true;
    spike_struct.data_file = events.data_file;
    spike_struct.unified_filename = un_filename;
    do_save( output_file, spike_struct );
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
  
  new_labs = cell( size(all_inds, 1), numel(new_cats) );
  
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
    
    unit_l = unit_labs{unit_ind};
    
    for k = 1:numel(new_cats)
      cat_ind = strcmp( unit_l.categories, new_cats{k} );
      cat_lab = unit_l.labels{cat_ind};
      new_labs{j, k} = cat_lab;
    end
    
    psth_matrix(j, :) = c_psth;
    raster_matrix(j, :) = c_raster;
  end
  
  event_inds = all_inds(:, 2);
  event_inds = [ event_inds{:} ];
  
  event_info = event_info(event_inds);
  
  for j = 1:numel(new_cats)
    event_info(new_cats{j}) = new_labs(:, j);
  end
  
  psth_cont = set_data( event_info, psth_matrix );
  raster_cont = set_data( event_info, raster_matrix );
  
  spike_struct = struct();
  spike_struct.raster = raster_cont;
  spike_struct.zpsth = Container();
  spike_struct.psth = psth_cont;
  spike_struct.null = Container();
  spike_struct.psth_t = psth_t;
  spike_struct.raster_t = raster_t;
  spike_struct.unified_filename = un_filename;
  spike_struct.params = params;
  
  do_save( output_file, spike_struct );
end

end

function do_save( filename, variable )
save( filename, 'variable' );
end