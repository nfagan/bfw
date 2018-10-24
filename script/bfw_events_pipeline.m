function bfw_events_pipeline(varargin)

%   BFW_EVENTS_PIPELINE -- Make events.

defaults = bfw.get_common_make_defaults();
params = bfw.parsestruct( defaults, varargin );

try
  handle_bounds( params );
catch err
  throw( err );
end

bfw.make_raw_aligned_samples( params, 'kinds', 'bounds' );
bfw.make_binned_raw_aligned_samples( params, 'kinds', 'bounds' );

bfw.make_raw_events( params ...
  , 'duration', 10 ...
  , 'fill_gaps', true ...
  , 'fill_gaps_duration', 150 ...
  , 'samples_subdir', 'aligned_binned_raw_samples' ...
  , 'fixations_subdir', 'arduino_fixations' ...
);

bfw.make_reformatted_raw_events( params );

end

function handle_bounds(params)

conf = params.config;

stim_labs = get_stim_labs( conf );

is_no_stim = find( stim_labs, 'no_stimulation' );
is_m1_excl = find( stim_labs, 'm1_exclusive_event' );
is_m1_radius = find( stim_labs, 'm1_radius_excluding_inner_rect' );

is_complete = isequal( union(union(is_no_stim, is_m1_excl), is_m1_radius) ...
  , rowmask(stim_labs) );
assert( is_complete, 'Some sessions were not accounted for.' );

no_stim_sessions = combs( stim_labs, 'session', is_no_stim );
m1_exclusive_sessions = combs( stim_labs, 'session', is_m1_excl );
m1_radius_sessions = combs( stim_labs, 'session', is_m1_radius );

% on no stim (just recording) sessions, no padding applied to eyes.
bfw.make_raw_bounds( params ...
  , 'files_containing', no_stim_sessions ...
  , 'padding', 0 ...
);

% on stim sessions to eyes, 5% padding applied to eyes, to match the 
% arduino's eyes roi.
bfw.make_raw_bounds( params ...
  , 'files_containing', m1_exclusive_sessions ...
  , 'padding', struct('eyes_nf', 0.05) ...
);

% on stim sessions to non-eyes, -5% padding to eyes, to match the arduino's
% non-eyes roi.
bfw.make_raw_bounds( params ...
  , 'files_containing', m1_radius_sessions ...
  , 'padding', struct('eyes_nf', -0.05) ...
);

end

function stim_labs = get_stim_labs(conf)

stim_meta_p = bfw.gid( 'stim_meta', conf );
meta_p = bfw.gid( 'meta', conf );

mats = shared_utils.io.find( stim_meta_p, '.mat' );
stim_labs = fcat();

for i = 1:numel(mats)
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
  
  append( stim_labs, labs );  
end

end