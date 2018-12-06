function bfw_plot_single_unit_event_trace(spikedat, spikelabs, varargin)

defaults = bfw.get_common_make_defaults();
defaults.mask = rowmask( spikelabs );
defaults.look_back = 0;
defaults.look_ahead = 100;
defaults.bin_size = 0.1;
defaults.marker_size = 5;
defaults.line_width = 1.5;
defaults.event_resolution = 1e-3;
defaults.use_binned_events = true;
defaults.event_types = { 'm1', 'm2', 'mutual' };
defaults.event_selectors = {};
defaults.save = false;
defaults.save_p = '';
defaults.xlim = [];
defaults.custom_color = true;
defaults.events_subdir = 'events_per_day';
defaults.y_shift_fraction = 0.05;

params = bfw.parsestruct( defaults, varargin );

conf = params.config;

events_p = bfw.gid( params.events_subdir, conf );
meta_p = bfw.gid( 'meta', conf );

assert_ispair( spikedat, spikelabs );

unified_filenames = combs( spikelabs, 'unified_filename', params.mask );

[eventdat, eventlabs] = get_event_data( events_p, meta_p, unified_filenames, params );

N = numel( params.mask );

for i = 1:N
  shared_utils.general.progress( i, N, mfilename );  
  one_unit( spikedat, spikelabs, params.mask(i), eventdat, eventlabs, params );
end

end

function one_unit(spikedat, spikelabs, spike_mask, eventdat, eventlabs, params)

assert( numel(spike_mask) == 1 );

un_filename = combs( spikelabs, 'session', spike_mask );

if ( ~isempty(params.event_selectors) )
  addtl_evt_selectors = { @find, params.event_selectors };
else
  addtl_evt_selectors = {};
end

event_mask = fcat.mask( eventlabs ...
  , @find, un_filename ...
  , @find, params.event_types ...
  , addtl_evt_selectors{:} ...
);

if ( isempty(event_mask) )
  return;
end

[evt_I, C] = findall( eventlabs, 'looks_by', event_mask );

spike_spec = { 'unit_uuid', 'session', 'region' };
spike_C = combs( spikelabs, spike_spec, spike_mask );
spike_title = strjoin( fcat.strjoin(spike_C, ' | '), ' | ' );

spikes = spikedat(spike_mask, :);
spike_ts = spikes{1};

evt_times = eventdat(event_mask, :);
evt_start_times = evt_times(:, 1);

start_evt = min( evt_start_times );

min_evt = start_evt + params.look_back;
max_evt = start_evt + params.look_ahead;

min_evt = floor( min_evt );
max_evt = ceil( max_evt );

t_series = min_evt:params.bin_size:max_evt;

spike_cts = histc( spike_ts, t_series );

figure(1);
clf();
hold on;

area( t_series, spike_cts );

if ( params.custom_color )
  colors = hsv( numel(evt_I) );
else
  colors = [];
end

ylims = get( gca, 'ylim' );
ydiff = diff( ylims );
decr = params.y_shift_fraction;

h = gobjects( numel(evt_I), 1 );

all_xs = [];
all_ys = [];
all_color_inds = [];
all_grps = fcat();

for i = 1:numel(evt_I)
  ind = evt_I{i};
  
  for j = 1:numel(ind)    
    tn = ind(j);
    
    evt_start_time = eventdat(tn, 1);
    evt_stop_time = eventdat(tn, 2);
    
    if ( params.use_binned_events )
      bin_start = shared_utils.sync.nearest_after( t_series, evt_start_time );
      bin_stop = shared_utils.sync.nearest_before( t_series, evt_stop_time );

      if ( bin_start == 0 || bin_stop == 0 ), continue; end

      bin_ind = bin_start:bin_stop;

      xs = t_series(bin_ind);
    else
      if ( evt_start_time < min_evt || evt_start_time > max_evt )
        continue;
      end
      
      xs = evt_start_time:params.event_resolution:evt_stop_time;
    end
    
    y = repmat( ylims(2) - ydiff * ((i-1) * decr), numel(xs), 1 );
    
    all_xs = [ all_xs; xs(:) ];
    all_ys = [ all_ys; y(:) ];
    all_color_inds = [ all_color_inds; repmat(i, numel(xs), 1) ];
    
    append1( all_grps, eventlabs, ind, numel(xs) );
  end
end

grp = categorical( prune(all_grps), 'looks_by' );

h = gscatter( all_xs, all_ys, grp, colors, [], params.marker_size );

ylabel( 'Spike counts' );
xlabel( 'Time (s from run start)' );

title( strrep(spike_title, '_', ' ') );

if ( ~isempty(params.xlim) )
  xlim( params.xlim );
end

if ( params.save )
  dsp3.req_savefig( gcf, params.save_p, spikelabs(spike_mask), spike_spec, 'run_trace__' );
end

end

function tf = is_old_evts(evts_p)
tf = strcmp( evts_p, 'events_per_day' );
end

function [eventdat, eventlabs] = get_event_data(events_p, meta_p, unified_filenames, params)

eventdat = [];
eventlabs = fcat();

for i = 1:numel(unified_filenames)
  shared_utils.general.progress( i, numel(unified_filenames) );
  
  unified_filename = unified_filenames{i};
  
  try
    events_file = bfw.load_intermediate( events_p, unified_filename );
    
    if ( is_old_evts(params.events_subdir) )
      orig_event_labs = events_file.event_info.labels;
      events_file = bfw.convert_events_per_day_to_new_format( events_file, unified_filename, false );
      labs = get_event_labels( meta_p, events_file, orig_event_labs );
    else
      metalabs = bfw.struct2fcat( bfw.load_intermediate(meta_p, unified_filename) );
      evtlabs = fcat.from( events_file.labels, events_file.categories );
      
      labs = join( evtlabs, metalabs );
    end
    
  catch err
    bfw.print_fail_warn( unified_filename, err.message );
    continue;
  end
  
  start_ts = events_file.events(:, events_file.event_key('start_time'));  
  
  if ( is_old_evts(params.events_subdir) )
    durs = events_file.events(:, events_file.event_key('duration'));
    stop_ts = start_ts + durs/1e3;
  else
    stop_ts = events_file.events(:, events_file.event_key('stop_time'));
  end
  
  eventdat = [ eventdat; [start_ts, stop_ts] ];
  append( eventlabs, labs );
end

assert_ispair( eventdat, eventlabs );

end

function evtlabs = get_event_labels(meta_p, events_file, event_info_labs)

evtlabs = fcat.from( events_file.labels, events_file.categories );

unified_filenames = unique( event_info_labs.full_categories('unified_filename') );

for i = 1:numel(unified_filenames)
  meta_file = bfw.load_intermediate( meta_p, unified_filenames{i} );
  meta_labs = bfw.struct2fcat( meta_file );
  
  unified_ind = find( where(event_info_labs, unified_filenames{i}) );
  
  meta_values = cellstr( meta_labs );
  meta_cats = getcats( meta_labs );
  
  addcat( evtlabs, meta_cats );
  
  for j = 1:numel(meta_cats)
    setcat( evtlabs, meta_cats{j}, meta_values(:, j), unified_ind );
  end
end

prune( evtlabs );

end