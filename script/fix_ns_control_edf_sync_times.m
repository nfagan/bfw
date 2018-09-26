function fix_ns_control_edf_sync_times(varargin)

defaults = bfw.get_common_make_defaults();

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;
osd = params.output_subdir;

unified_p = bfw.gid( fullfile('unified', isd), conf );
edf_p = bfw.gid( fullfile('edf', isd), conf );
save_p = bfw.gid( fullfile('edf_sync', osd), conf );

unified_mats = bfw.require_intermediate_mats( params.files, unified_p, params.files_containing );

for i = 1:numel(unified_mats)
  shared_utils.general.progress( i, numel(unified_mats) );
  
  unified_file = shared_utils.io.fload( unified_mats{i} );
  unified_filename = get_un_filename( unified_file );
  
  output_filename = fullfile( save_p, unified_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  if ( ~is_ns_control(unified_file) )
    print_skip_message( unified_filename, 'it is not a nonsocial control.' );
    continue;
  end
  
  edf_filename = fullfile( edf_p, unified_filename );
  
  if ( ~shared_utils.io.fexists(edf_filename) )
    print_skip_message( unified_filename, 'the corresponding edf file does not exist.' );
    continue;
  end
  
  edf_file = shared_utils.io.fload( edf_filename );
  
  fs = intersect( fieldnames(edf_file), {'m1', 'm2'} );
  
  save_sync_times = true;
  
  sync_times_file = struct();
  
  for j = 1:numel(fs)   
    edf = edf_file.(fs{j}).edf;
    sync_times = unified_file.(fs{j}).plex_sync_times;
    
    try 
      fixed_times = fix_edf( edf, sync_times );
    catch err
      save_sync_times = false;
      print_skip_message( unified_filename, sprintf('an error occurred: %s', err.message) );
      break;
    end
    
    sync_times_file.(fs{j}).unified_filename = unified_filename;
    sync_times_file.(fs{j}).edf_sync_times = fixed_times;
  end
  
  if ( ~save_sync_times )
    continue;
  end
  
  shared_utils.io.require_dir( save_p );
  shared_utils.io.psave( output_filename, sync_times_file, 'sync_times' );
end

end

function fixed_times = fix_edf(edf, sync_times)

t = edf.Events.Messages.time;
info = edf.Events.Messages.info;

is_sync_msg = strcmp( info, 'SYNCH' );
is_resync_msg = strcmp( info, 'RESYNCH' );

assert( sum(is_sync_msg) == 1, 'No starting synch message was found.' );

resync_t = t( is_resync_msg );

diffed_t = diff( resync_t );

% first resync time is valid
% subsequent resync times occur at an interval of at least 100ms

is_valid_resync = [ true, diffed_t > 100 ];

assert( sum(is_valid_resync) == numel(sync_times)-1 ...
  , 'Number of resync times does not match given number of mat sync times.' );

fixed_times = [ t(is_sync_msg), resync_t(is_valid_resync) ];

end

function print_skip_message(un_file, reason)
fprintf( '\n Skipping "%s" because %s', un_file, reason );
end

function tf = is_ns_control(s)

fs = fieldnames( s );
f = fs{1};

has_task_type = isstruct(s.(f)) && isfield( s.(f), 'task_type' );
tf = has_task_type && strcmp( s.(f).task_type, 'nonsocial_control' );

end

function u = get_un_filename(s)

fs = fieldnames( s );
f = fs{1};
u = s.(f).unified_filename;

end