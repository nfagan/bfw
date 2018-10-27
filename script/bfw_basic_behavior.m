function outs = bfw_basic_behavior(varargin)

defaults = bfw.get_common_make_defaults();
defaults.events_subdir = 'raw_events';

params = bfw.parsestruct( defaults, varargin );
conf = params.config;
esd = params.events_subdir;

event_p = bfw.gid( esd, conf );
meta_p = bfw.gid( 'meta', conf );
mats = bfw.rim( params.files, event_p, params.files_containing );

is_old_evts = is_old_events( esd );

all_event_info = cell( numel(mats), 1 );
all_event_keys = cell( size(all_event_info) );
all_labs = cell( size(all_event_info) );
all_cats = cell( size(all_event_info) );
is_ok = true( size(all_event_info) );

parfor i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats), mfilename );
  
  events_file = shared_utils.io.fload( mats{i} );
  
  unified_filename = events_file.unified_filename;
  
  if ( false ), is_ok(i); end
  
  try
    meta_file = bfw.load_intermediate( meta_p, unified_filename );
    
  catch err
    bfw.print_fail_warn( unified_filename, err.message );
    is_ok(i) = false;
    continue;
  end
  
  events_file = get_events_file( events_file, unified_filename, is_old_evts );
  
  labs = fcat.from( events_file.labels, events_file.categories );
  join( labs, bfw.struct2fcat(meta_file) );
  
  all_event_info{i} = events_file.events;
  all_event_keys{i} = events_file.event_key;
  all_labs{i} = labs;
  all_cats{i} = columnize( cellstr(events_file.categories) );
end

total_cats = unique( vertcat(all_cats{is_ok}) );

cellfun( @(x) addcat(x, total_cats), all_labs(is_ok), 'un', 0 );

outs = struct();
outs.events = vertcat( all_event_info{is_ok} );

all_event_keys = all_event_keys(is_ok);

if ( ~isempty(all_event_keys) )
  outs.event_key = all_event_keys{1};
else
  outs.event_key = [];
end

outs.labels = vertcat( fcat(), all_labs{is_ok} );

end

function events_file = get_events_file(events_file, unified_filename, is_old_evts)

if ( ~is_old_evts )
  return
end

if ( events_file.is_link )
  events_file = bfw.load_intermediate( event_p, events_file.data_file );
  events_file.event_info = only( events_file.event_info, unified_filename );
end

events_file = bfw.convert_events_per_day_to_new_format( events_file, unified_filename );

end

function tf = is_old_events(esd)
tf = strcmp( esd, 'events_per_day' );
end