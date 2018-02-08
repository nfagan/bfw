function make_modulation_type(varargin)

defaults = bfw.get_common_make_defaults();
defaults.look_back = -0.5;
defaults.look_ahead = 0.5;
defaults.psth_bin_size = 0.01;
defaults.window_pre = [ -0.2, 0 ];
defaults.window_post = [ 0, 0.2 ];
defaults.raster_fs = 1e3;
defaults.null_fs = 40e3;
defaults.null_n_iterations = 1e3;
defaults.alpha = 0.025;

params = bfw.parsestruct( defaults, varargin );

event_p = bfw.get_intermediate_directory( 'events_per_day' );
spike_p = bfw.get_intermediate_directory( 'spikes' );
output_p = bfw.get_intermediate_directory( 'modulation_type' );

params.output_p = output_p;

event_mats = bfw.require_intermediate_mats( params.files, event_p, params.files_containing );

processed_already = containers.Map();

for i = 1:numel(event_mats)
  
  events = shared_utils.io.fload( event_mats{i} );
  
  unified_filename = events.unified_filename;
  
  full_filename = fullfile( output_p, unified_filename );
  
  if ( bfw.conditional_skip_file(full_filename, params.overwrite) )
    continue;
  end
  
  if ( events.is_link )
    events = shared_utils.io.fload( fullfile(event_p, events.data_file) );
  end
  
  spike_file = fullfile( spike_p, unified_filename );
  
  if ( ~shared_utils.io.fexists(spike_file) )
    fprintf( '\n No spike file for "%s".', unified_filename );
    continue;
  end
  
  spikes = shared_utils.io.fload( spike_file );
  
  if ( spikes.is_link )
    spikes = shared_utils.io.fload( fullfile(spike_p, spikes.data_file) );
  end
  
  units = spikes.data;
  
  if ( ~processed_already.isKey(events.unified_filename) )
    handle_units( units, events, params );
    processed_already(events.unified_filename) = true;
  else
    spike_struct = struct();
    spike_struct.is_link = true;
    spike_struct.data_file = events.unified_filename;
    save( full_filename, 'spike_struct' );
  end
end

end

function handle_units( units, events, params )

event_info = events.event_info;
info_key = events.event_info_key;

event_times_cont = set_data( event_info, event_info.data(:, info_key('times')) );

[I, C] = event_times_cont.get_indices( {'looks_to', 'looks_by'} );

look_ahead = params.look_ahead;
look_back = params.look_back;
psth_bin_size = params.psth_bin_size;
n_iterations = params.null_n_iterations;
null_fs = params.null_fs;
raster_fs = params.raster_fs;
window_pre = params.window_pre;
window_post = params.window_post;
alpha = params.alpha;

output_p = params.output_p;

unit_indices = arrayfun( @(x) x, 1:numel(units), 'un', false );
event_indices = arrayfun( @(x) x, 1:numel(I), 'un', false );
all_indices = bfw.allcomb( {unit_indices, event_indices} );

rasters = cell(1, size(all_indices, 1));
psth = cell( size(rasters) );
null_psth = cell( size(psth) );
to_remove = false( size(psth) );

final_raster_t = cell( size(psth) );
final_psth_t = cell( size(psth) );

parfor i = 1:size(all_indices, 1)
  unit_index = all_indices{i, 1};
  event_index = all_indices{i, 2};
  
  unit = units(unit_index);

  spike_times = unit.times;

  evts = event_times_cont(I{event_index});
  
  event_times = evts.data;
  
  min_spk = min( spike_times );
  max_spk = max( spike_times );
  
  ind = event_times >= (min_spk + look_back) & event_times <= (max_spk + look_ahead);
  
  evts = evts(ind);
  event_times = event_times(ind);
  
  if ( numel(event_times) == 0 )
    to_remove(i) = true;
    continue; 
  end
    
  [real_psth, psth_t] = looplessPSTH( spike_times, event_times ...
    , look_back, look_ahead, psth_bin_size );
  
  fake_psth = bfw.generate_null_psth( spike_times, event_times ...
    , look_back, look_ahead, psth_bin_size, n_iterations, null_fs );
  
  window_pre_ind = psth_t >= window_pre(1) & psth_t < window_pre(2);
  window_post_ind = psth_t >= window_post(1) & psth_t < window_post(2);
  
  real_pre = mean( real_psth(:, window_pre_ind), 2 );
  real_post = mean( real_psth(:, window_post_ind), 2 );
  
  fake_pre = nanmean( fake_psth(:, window_pre_ind), 2 );
  fake_post = nanmean( fake_psth(:, window_post_ind), 2 );
  
  n_greater_pre = 0;
  n_greater_post = 0;
  
  for j = 1:n_iterations
    if ( real_pre > fake_pre(j) )
      n_greater_pre = n_greater_pre + 1;
    end
    if ( real_post > fake_post(j) )
      n_greater_post = n_greater_post + 1;
    end
  end
  
  p_pre = 1 - (n_greater_pre / n_iterations);
  p_post = 1 - (n_greater_post / n_iterations);
  
  sig_pre = p_pre <= alpha;
  sig_post = p_post <= alpha;

  is_pre_only = sig_pre && ~sig_post;
  is_post_only = sig_post && ~sig_pre;
  is_pre_and_post = sig_pre && sig_post;
  is_none = ~sig_pre && ~sig_post;
  
  if ( is_pre_only )
    cell_type = 'pre';
  elseif ( is_post_only )
    cell_type = 'post';
  elseif ( is_pre_and_post )
    cell_type = 'pre_and_post';
  else
    cell_type = 'none';
  end
  
  unit_labels = bfw.get_unit_labels( unit, 'cell_type', cell_type );
  
  psth_labels = one( evts );
  raster_labels = evts;
  
  cats = setdiff( unit_labels.categories(), psth_labels.categories() );
  psth_labels = psth_labels.require_fields( cats );
  raster_labels = raster_labels.require_fields( cats );
  
  for j = 1:numel(cats)
    unqs = unit_labels.labels_in_category( cats{j} );
    psth_labels(cats{j}) = unqs;
    raster_labels(cats{j}) = unqs;
  end
  
  [raster, raster_t] = bfw.make_raster( spike_times, event_times, look_back, look_ahead, raster_fs );
  raster = double( raster );
  
  final_raster_t{i} = raster_t;
  final_psth_t{i} = psth_t;
  
  psth{i} = Container( real_psth, psth_labels.labels );
  null_psth{i} = Container( fake_psth, psth_labels.labels );
  rasters{i} = Container( raster, raster_labels.labels );
end

psth( to_remove ) = [];
null_psth( to_remove ) = [];
rasters( to_remove )  = [];

psth = Container.concat( psth );
null_psth = Container.concat( null_psth );
rasters = Container.concat( rasters );
rasters.data = rasters.data == 1; % convert back to logical

spike_struct = struct();
spike_struct.is_link = false;
spike_struct.raster = rasters;
spike_struct.zpsth = Container();
spike_struct.psth = psth;
spike_struct.null = null_psth;
spike_struct.psth_t = final_psth_t{1};
spike_struct.raster_t = final_raster_t{1};
spike_struct.unified_filename = events.unified_filename;
spike_struct.params = params;

shared_utils.io.require_dir( output_p );

save( fullfile(output_p, events.unified_filename), 'spike_struct' );

end