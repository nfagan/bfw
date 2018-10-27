function sessions = get_sessions_by_stim_type(conf, varargin)

defaults.cache = false;
params = bfw.parsestruct( defaults, varargin );

persistent use_sessions;

if ( nargin < 1 || isempty(conf) )
  conf = bfw.config.load();
else
  bfw.util.assertions.assert__is_config( conf );
end

if ( params.cache && ~isempty(use_sessions) )
  fprintf( '\n Using cached data ...' );
  sessions = use_sessions;
  return
end

stim_labs = get_stim_labs( conf );

is_no_stim = find( stim_labs, 'no_stimulation' );
is_m1_excl = find( stim_labs, 'm1_exclusive_event' );
is_m1_radius = find( stim_labs, 'm1_radius_excluding_inner_rect' );

is_complete = isequal( union(union(is_no_stim, is_m1_excl), is_m1_radius) ...
  , rowmask(stim_labs) );
assert( is_complete, 'Some sessions were not accounted for.' );

sessions = struct();
sessions.no_stim_sessions = combs( stim_labs, 'session', is_no_stim );
sessions.m1_exclusive_sessions = combs( stim_labs, 'session', is_m1_excl );
sessions.m1_radius_sessions = combs( stim_labs, 'session', is_m1_radius );

use_sessions = sessions;

end

function stim_labs = get_stim_labs(conf)

stim_meta_p = bfw.gid( 'stim_meta', conf );
meta_p = bfw.gid( 'meta', conf );

mats = shared_utils.io.find( stim_meta_p, '.mat' );
stim_labs = cell( numel(mats), 1 );

parfor i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats) );
  
  stim_meta_file = shared_utils.io.fload( mats{i} );
  
  unified_filename = stim_meta_file.unified_filename;
  
  try
    meta_file = shared_utils.io.fload( fullfile(meta_p, unified_filename) );
  catch err
    bfw.print_fail_warn( unified_filename, err.message );
    continue;
  end
  
  if ( stim_meta_file.used_stimulation )
    stim_protocol = stim_meta_file.protocol_name;
  else
    stim_protocol = 'no_stimulation';
  end
  
  labs = bfw.struct2fcat( meta_file );
  addsetcat( labs, 'stimulation_protocol', stim_protocol );
  stim_labs{i} = labs;
end

stim_labs = vertcat( fcat(), stim_labs{:} );

end