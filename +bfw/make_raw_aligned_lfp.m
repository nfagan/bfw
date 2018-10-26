function make_raw_aligned_lfp(varargin)

import shared_utils.io.fload;

defaults = bfw.get_common_make_defaults();
defaults.events_subdir = 'raw_events';
defaults.window_size = 150;
defaults.look_back = -500;
defaults.look_ahead = 500;
defaults.sample_rate = 1e3;
defaults.event_types = [];
defaults.cache = false;

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;
osd = params.output_subdir;
esd = params.events_subdir;
files = params.files;
fc = params.files_containing;
do_cache = params.cache;

event_p = bfw.gid( fullfile(esd, isd), conf );
lfp_p = bfw.gid( fullfile('lfp', isd), conf );
aligned_p = bfw.gid( fullfile('raw_aligned_lfp', osd), conf );

mats = bfw.require_intermediate_mats( files, event_p, fc );

spmd

lfp_map = containers.Map();
loop_inds = get_loop_indices( numel(mats), numlabs );

for i = loop_inds
  shared_utils.general.progress( i, numel(mats), mfilename );

  events_file = get_events_file( mats{i}, esd, event_p );

  unified_filename = events_file.unified_filename;
  output_filename = fullfile( aligned_p, unified_filename );

  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end

  try
    base_lfp_file = fload( fullfile(lfp_p, unified_filename) );
    lfp_file = get_lfp_file( base_lfp_file, lfp_map, lfp_p, unified_filename, do_cache );

    aligned_file = get_aligned_lfp( lfp_file, events_file, unified_filename, params );
    
    shared_utils.io.require_dir( aligned_p );
    shared_utils.io.psave( output_filename, aligned_file, 'aligned_file' );

  catch err
    bfw.print_fail_warn( unified_filename, err.message );
    continue;
  end
end

end

end

function aligned_file = get_aligned_lfp(lfp_file, events_file, unified_filename, params)

events = events_file.events;
event_key = events_file.event_key;

n_events = rows( events );
n_channels = rows( lfp_file.data );

event_inds = 1:n_events;
chan_inds = 1:n_channels;

c = combvec( chan_inds, event_inds );
n_combs = size( c, 2 );

event_times = events(:, event_key('start_time'));
t = lfp_file.id_times;
lfp_key = lfp_file.key;
id_time_inds = arrayfun( @(x) shared_utils.sync.nearest(t, x), event_times );

look_ahead = params.look_ahead;
look_back = params.look_back;
window_size = params.window_size;

total_n_samples = look_ahead - look_back + window_size;
all_lfp_data = nan( n_events * n_channels, total_n_samples );

lfp_keys = keys( lfp_file.key_column_map );
[~, I] = sort( cellfun(@(x) lfp_file.key_column_map(x), lfp_keys) );

event_labs = fcat.from( events_file.labels, events_file.categories );

lfp_cats = lfp_keys(I);
lfp_labs = fcat.from( lfp_key, lfp_cats );

join( event_labs, one(lfp_labs) );

all_labs = resize( fcat.like(event_labs), n_combs );

for i = 1:n_combs
  chani = c(1, i);
  evti = c(2, i);
  
  id_ind = id_time_inds(evti);
  
  start = floor( id_ind + look_back - (window_size/2) );
  stop = floor( id_ind + look_ahead + window_size - (window_size/2) );
  
  if ( start > 0 && stop <= numel(t) + 1 )
    all_lfp_data(i, :) = lfp_file.data(chani, start:stop-1);
  end
  
  assign( all_labs, event_labs, i, evti );
  setcat( all_labs, lfp_cats, lfp_file.key(chani, :), i );
end

aligned_file = struct();
aligned_file.params = params;
aligned_file.unified_filename = unified_filename;
aligned_file.data = all_lfp_data;
aligned_file.labels = categorical( all_labs );
aligned_file.categories = getcats( all_labs );
aligned_file.lfp_indices = c(1, :);
aligned_file.event_indices = c(2, :);

end

function lfp_file = get_lfp_file(lfp_file, lfp_map, lfp_p, unified_filename, do_cache)

import shared_utils.io.fload;

if ( ~lfp_file.is_link )
  return
end

if ( isKey(lfp_map, unified_filename) )
  lfp_file = lfp_map(unified_filename);
else
  lfp_file = fload( fullfile(lfp_p, lfp_file.data_file) );
  
  if ( do_cache )
    lfp_map(unified_filename) = lfp_file;
  end
end

end

function idx = get_loop_indices(n_mats, n_workers)

all_indices = shared_utils.vector.distribute( 1:n_mats, n_workers );
idx = all_indices{labindex};

end

function tf = is_old_events(esd)
tf = strcmp( esd, 'events_per_day' );
end

function events_file = get_events_file(full_filename, events_subdir, event_p)

events_file = shared_utils.io.fload( full_filename );

if ( ~is_old_events(events_subdir) )
  return
end

un_filename = events_file.unified_filename;

if ( events_file.is_link )
  events_file = shared_utils.io.fload( fullfile(event_p, events_file.data_file) );
end

events_file = convert_events_per_day_to_new_format( events_file, un_filename );

end

function out_file = convert_events_per_day_to_new_format(events_file, unified_filename)

event_info = only( events_file.event_info, unified_filename );

event_info_data = event_info.data;
event_info_labs = fcat.from( event_info.labels );

renamecat( event_info_labs, 'look_order', 'initiator' );
renamecat( event_info_labs, 'looks_to', 'roi' );
rmcat( event_info_labs, {'session_name', 'unified_filename'} );

is_mut = find( event_info_labs, 'mutual' );

if ( ~isempty(event_info_labs) )
  addsetcat( event_info_labs, 'event_type', 'exclusive_event' );
  setcat( event_info_labs, 'event_type', 'mutual_event', is_mut );
end

replace( event_info_labs, 'look_order__m1', 'm1_initiated' );
replace( event_info_labs, 'look_order__m2', 'm2_initiated' );
replace( event_info_labs, 'look_order__simultaneous', '<initiator>' );
replace( event_info_labs, 'look_order__NaN', '<initiator>' );

prune( event_info_labs );

event_key = containers.Map();
event_key('duration') = events_file.event_info_key('durations');
event_key('length') = events_file.event_info_key('lengths');
event_key('start_time') = events_file.event_info_key('times');

out_file = struct();
out_file.unified_filename = unified_filename;
out_file.events = event_info_data;
out_file.categories = columnize( getcats(event_info_labs) )';
out_file.labels = cellstr( event_info_labs );
out_file.event_key = event_key;

end