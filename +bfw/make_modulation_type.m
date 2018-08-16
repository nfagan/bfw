function make_modulation_type(varargin)

ff = @fullfile;

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
defaults.sig_test_type = 'z';

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;
osd = params.output_subdir;

event_p = bfw.gid( ff('events_per_day', isd), conf );
spike_p = bfw.gid( ff('spikes', isd), conf );
start_p = bfw.gid( ff('start_stop', isd), conf );
output_p = bfw.gid( ff('modulation_type', osd), conf );

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
  
  %   get start_stop times for each run
  un_filenames = events.event_info('unified_filename');
  can_proceed = true;
  evt_labs = one( events.event_info.labels );
  
  start_stop_cont = Container();
  
  for j = 1:numel(un_filenames)
    if ( ~can_proceed ), continue; end
    start_stop_file = fullfile( start_p, un_filenames{j} );
    if ( ~shared_utils.io.fexists(start_stop_file) )
      fprintf( '\n Warning: missing start_stop file for "%s".', un_filenames{j} );
      can_proceed = false;
      continue;
    end
    start_stop_file = shared_utils.io.fload( start_stop_file );
    start_stop_times = [start_stop_file.fv_plex_start, start_stop_file.fv_plex_stop];
    start_stop = Container( start_stop_times, evt_labs );
    start_stop('unified_filename') = un_filenames{j};
    start_stop_cont = append( start_stop_cont, start_stop );
  end
  
  if ( ~can_proceed ), continue; end
  
  spikes = shared_utils.io.fload( spike_file );
  
  if ( spikes.is_link )
    spikes = shared_utils.io.fload( fullfile(spike_p, spikes.data_file) );
  end
  
  units = spikes.data;
  
  if ( ~processed_already.isKey(events.unified_filename) )
    handle_units( units, events, start_stop_cont, params );
    processed_already(events.unified_filename) = true;
  else
    spike_struct = struct();
    spike_struct.is_link = true;
    spike_struct.data_file = events.unified_filename;
    save( full_filename, 'spike_struct' );
  end
end

end

function handle_units( units, events, start_stops, params )

event_info = events.event_info;
info_key = events.event_info_key;

event_times_cont = set_data( event_info, event_info.data(:, info_key('times')) );
event_times_cont = event_times_cont.rm( {'m1_leads_m2', 'm2_leads_m1'} );

[I, C] = event_times_cont.get_indices( {'looks_to', 'looks_by', 'unified_filename'} );

look_ahead = params.look_ahead;
look_back = params.look_back;
psth_bin_size = params.psth_bin_size;
n_iterations = params.null_n_iterations;
null_fs = params.null_fs;
raster_fs = params.raster_fs;
window_pre = params.window_pre;
window_post = params.window_post;
alpha = params.alpha;
sig_method = params.sig_test_type;

assert( any(strcmp({'z', 'gt'}, sig_method)), 'Unrecognized `sig_test_type` "%s".' ...
  , sig_method );

output_p = params.output_p;

unit_indices = arrayfun( @(x) x, 1:numel(units), 'un', false );
event_indices = arrayfun( @(x) x, 1:numel(I), 'un', false );
all_indices = bfw.allcomb( {unit_indices, event_indices} );

rasters = cell(1, size(all_indices, 1));
psth = cell( size(rasters) );
null_psth = cell( size(psth) );
zpsths = cell( size(psth) );
to_remove = false( size(psth) );

final_raster_t = cell( size(psth) );
final_psth_t = cell( size(psth) );

for i = 1:size(all_indices, 1)
  unit_index = all_indices{i, 1};
  event_index = all_indices{i, 2};
  
  un_filename = C{event_index, 3};
  
  unit = units(unit_index);

  spike_times = unit.times;

  evts = event_times_cont(I{event_index});
  
  event_times = evts.data;
  
  matching_start_stop = start_stops({un_filename});
  
  assert( shape(matching_start_stop, 1) == 1, 'Expected 1 element; got %d.' ...
    , shape(matching_start_stop, 1) );
  
  start_t = matching_start_stop.data(1);
  stop_t = matching_start_stop.data(2);
  
  spike_times = spike_times( spike_times >= start_t & spike_times <= stop_t );
  
  if ( isempty(spike_times) )
    to_remove(i) = true;
    continue;
  end
  
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
 
  if ( strcmp(sig_method, 'gt') )
    p_pre = test_gt( real_pre, fake_pre );
    p_post = test_gt( real_pre, fake_pre );
    z_pre = NaN;
    z_post = NaN;
  elseif ( strcmp(sig_method, 'z') )
    [z_pre, p_pre] = test_z( real_pre, fake_pre );
    [z_post, p_post] = test_z( real_post, fake_post );
    z_psth = test_z( real_psth, fake_psth );
    %   end test-z
  else
    assert( false );
  end
  
  sig_pre = p_pre <= alpha;
  sig_post = p_post <= alpha;

  is_pre_only = sig_pre && ~sig_post;
  is_post_only = sig_post && ~sig_pre;
  is_pre_and_post = sig_pre && sig_post;
  
  if ( is_pre_only )
    cell_type = 'pre';
  elseif ( is_post_only )
    cell_type = 'post';
  elseif ( is_pre_and_post )
    cell_type = 'pre_and_post';
  else
    cell_type = 'none';
  end
  
  mean_fake_pre = nanmean( fake_pre, 1 );
  mean_fake_post = nanmean( fake_post, 1 );
  
  if ( strcmp(cell_type, 'pre') )
    mod_sign = sign( real_pre - mean_fake_pre );
  elseif ( strcmp(cell_type, 'post') )
    mod_sign = sign( real_post - mean_fake_post );
  else
    mod_sign_pre = sign( real_pre - mean_fake_pre );
    mod_sign_post = sign( real_post - mean_fake_post );
    if ( mod_sign_pre == mod_sign_post )
      mod_sign = mod_sign_pre;
    else
      mod_sign = 2;
    end
  end
  
  if ( mod_sign ~= 2 )
    mod_direction = get_string_modulation_direction( mod_sign );
  else
    mod_pre = get_string_modulation_direction( mod_sign_pre );
    mod_post = get_string_modulation_direction( mod_sign_post );
    mod_direction = strjoin( {mod_pre, mod_post}, '_' );
  end
  
  unit_labels = bfw.get_unit_labels( unit ...
    , 'cell_type', cell_type, 'modulation_direction', mod_direction );
  
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
  null_psth{i} = Container( nanmean(fake_psth, 1), psth_labels.labels );
  rasters{i} = Container( raster, raster_labels.labels );
%   zpsths{i} = Container( [z_pre, z_post], psth_labels.labels );
  zpsths{i} = Container( z_psth, psth_labels.labels );
end

psth( to_remove ) = [];
null_psth( to_remove ) = [];
rasters( to_remove )  = [];
zpsths( to_remove) = [];

psth = Container.concat( psth );
zpsth = Container.concat( zpsths );
null_psth = Container.concat( null_psth );
rasters = Container.concat( rasters );
rasters.data = rasters.data == 1; % convert back to logical

spike_struct = struct();
spike_struct.is_link = false;
spike_struct.raster = rasters;
spike_struct.zpsth = zpsth;
spike_struct.psth = psth;
spike_struct.null = null_psth;
spike_struct.psth_t = final_psth_t{1};
spike_struct.raster_t = final_raster_t{1};
spike_struct.unified_filename = events.unified_filename;
spike_struct.params = params;

shared_utils.io.require_dir( output_p );

save( fullfile(output_p, events.unified_filename), 'spike_struct' );

end

function mod_direction = get_string_modulation_direction( mod_sign )

if ( mod_sign == -1 )
  mod_direction = 'suppress';
elseif ( mod_sign == 1 )
  mod_direction = 'enhance';
elseif ( mod_sign == 0 )
  mod_direction = 'direction__null';
else
  error( 'Mod sign was %d', mod_sign );
end

end

function [z, p] = test_z( real, fake )

means = nanmean( fake, 1 );
devs = nanstd( fake, [], 1 );
z = (real - means) ./ devs;
p = 1 - normcdf( abs(z) );

end

function p = test_gt( real, fake )

n_iters = numel( fake );
n_greater = sum( real > fake );
p = 1 - ( n_greater / n_iters );

end