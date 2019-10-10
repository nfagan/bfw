function outs = bfw_get_plex_start_stop(varargin)

defaults = bfw.get_common_make_defaults();
params = bfw.parsestruct( defaults, varargin );

unified_files = bfw.find_intermediates( 'unified', params.config );
cs_unified_files = bfw.find_intermediates( 'cs_unified/m1', params.config );

unified_filenames = shared_utils.io.filenames( unified_files );
cs_unified_filenames = shared_utils.io.filenames( cs_unified_files );

[sessions, run_nums] = parse_filenames( unified_filenames, 2 );
[cs_sessions, cs_run_nums] = parse_filenames( cs_unified_filenames, 4 );

all_sessions = union( sessions(:), cs_sessions(:) );

labels = cell( numel(all_sessions), 1 );
start_stops = cell( size(labels) );
to_keep = true( size(labels) );

parfor i = 1:numel(all_sessions)
  session = all_sessions{i};
  
  min_max_nums = min_max_run( sessions, run_nums, session );
  cs_min_max_nums = min_max_run( cs_sessions, cs_run_nums, session );
  
  min_file = '';
  max_file = '';
  cs_min_file = '';
  cs_max_file = '';
  
  if ( ~isnan(min_max_nums(1)) )
    min_file = unified_filenames{strcmp(sessions, session) & run_nums == min_max_nums(1)};
    max_file = unified_filenames{strcmp(sessions, session) & run_nums == min_max_nums(2)};
  end
  
  if ( ~isnan(cs_min_max_nums(1)) )
    cs_min_file = cs_unified_filenames{strcmp(cs_sessions, session) & cs_run_nums == cs_min_max_nums(1)};
    cs_max_file = cs_unified_filenames{strcmp(cs_sessions, session) & cs_run_nums == cs_min_max_nums(2)};
  end
  
  min_t = inf;
  max_t = -inf;
  
  try
    if ( ~isempty(min_file) )
      tmp = min( plex_sync(bfw.load1('sync', min_file, params.config)) ); 
      [min_t, max_t] = check_min_max( tmp, min_t, max_t );
    end
    if ( ~isempty(max_file) )
      tmp = max( plex_sync(bfw.load1( 'sync', max_file, params.config)) );
      [min_t, max_t] = check_min_max( tmp, min_t, max_t );
    end
    if ( ~isempty(cs_min_file) )
      tmp = min( plex_sync(bfw.load1( 'cs_sync/m1', cs_min_file, params.config)) );
      [min_t, max_t] = check_min_max( tmp, min_t, max_t );
    end
    if ( ~isempty(cs_max_file) )
      tmp = max( plex_sync(bfw.load1('cs_sync/m1', cs_max_file, params.config)) );
      [min_t, max_t] = check_min_max( tmp, min_t, max_t );
    end
  catch err
    warning( err.message );
    
    min_t = nan;
    max_t = nan;
  end
  
  if ( isfinite(min_t) && isfinite(max_t) )
    labels{i} = fcat.create( 'session', session );
    start_stops{i} = [ min_t, max_t ];
  else
    to_keep(i) = false;
  end
end

labels = vertcat( fcat, labels{to_keep} );
start_stops = vertcat( start_stops{to_keep} );

outs = struct();
outs.labels = labels;
outs.start_stops = start_stops;

end

function [min_t, max_t] = check_min_max(tmp, min_t, max_t)

if ( tmp < min_t )
  min_t = tmp;
end
if ( tmp > max_t )
  max_t = tmp;
end

end

function t = plex_sync(sync_file)

if ( isempty(sync_file) )
  t = nan;
else
  t = sync_file.plex_sync(:, strcmp(sync_file.sync_key, 'plex'));
end

end

function spans = min_max_run(sessions, run_nums, session)

sesh_ind = strcmp( sessions, session );

if ( nnz(sesh_ind) == 0 )
  min_run = nan;
  max_run = nan;
else
  nums = run_nums(sesh_ind);
  
  min_run = min( nums );
  max_run = max( nums );
end

spans = [ min_run, max_run ];

end

function [sessions, run_nums] = parse_filenames(filenames, num_underscores)

sessions = cellfun( @(x) x(1:8), filenames, 'un', 0 );
run_nums = cellfun( @(x) unified_filename_run_numbers(x, num_underscores), filenames );

end

function num = unified_filename_run_numbers(filename, num_underscores)

underscores = strfind( filename, '_' );

if ( numel(underscores) ~= num_underscores )
  num = nan;
else
  num = str2double( filename((underscores(num_underscores)+1):end) );
end

end