function [ib, labs, plot_t] = debug_stim_times(varargin)

import shared_utils.io.fload;

defaults = bfw.get_common_make_defaults();
params = bfw.parsestruct( defaults, varargin );

conf = params.config;

unified_p = bfw.gid( 'unified', conf );
stim_p = bfw.gid( 'stim', conf );
mat_sync_p = bfw.gid( 'sync', conf );
edf_samples_p = bfw.gid( 'edf_raw_samples', conf );
edf_sync_p = bfw.gid( 'edf_sync', conf );
roi_p = bfw.gid( 'rois', conf );

look_ahead = 5;
look_back = -1;
fs = 1/1e3;

plot_t = look_back:fs:look_ahead;

mats = bfw.require_intermediate_mats( params.files, stim_p, params.files_containing );

all_ib = cell( size(mats) );
all_labs = cell( size(mats) );
is_ok = true( size(mats) );

parfor i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats) );
  
  stim_file = fload( mats{i} );

  unified_filename = stim_file.unified_filename;

  try
    un_file = fload( fullfile(unified_p, unified_filename) );
    mat_sync_file = fload( fullfile(mat_sync_p, unified_filename) );
    edf_sync_file = fload( fullfile(edf_sync_p, unified_filename) );
    edf_samples_file = fload( fullfile(edf_samples_p, unified_filename) );
    roi_file = fload( fullfile(roi_p, unified_filename) );
  catch err
    warning( err.message );
    is_ok(i) = false;
    continue;
  end

  process_params = struct();
  process_params.look_ahead = look_ahead;
  process_params.look_back = look_back;
  process_params.time = plot_t;

  try 
    [ib, labs] = one_file( un_file, stim_file, mat_sync_file, edf_sync_file, edf_samples_file, roi_file, process_params );
  catch err
    warning( '"%s" (%d) failed with message: "%s"', unified_filename, i, err.message );
    is_ok(i) = false;
    continue;
  end
  
  try
    all_ib{i} = ib;
    all_labs{i} = labs;
  catch err
    warning( '"%s" (%d) failed with message: "%s"', unified_filename, i, err.message );
    is_ok(i) = false;
    continue;
  end
end

all_ib(~is_ok) = [];
all_labs(~is_ok) = [];

labs = vertcat( fcat(), all_labs{:} );
ib = vertcat( all_ib{:} );

end

function [all_aligned_ib, all_labs] = one_file(un_file, stim_file, mat_sync_file, edf_sync_file, edf_samples_file, roi_file, params)

lb = params.look_back;
la = params.look_ahead;
t = params.time;

m_ind = strcmp( mat_sync_file.sync_key, 'mat' );
p_ind = strcmp( mat_sync_file.sync_key, 'plex' );

edf_time = edf_samples_file.m1.t;
edf_x = edf_samples_file.m1.x;
edf_y = edf_samples_file.m1.y;

edf_sync_times = edf_sync_file.m1.edf_sync_times;
mat_sync_times = mat_sync_file.plex_sync(2:end, m_ind);
plex_sync_times = mat_sync_file.plex_sync(2:end, p_ind);

assert( numel(edf_sync_times) == numel(mat_sync_times) && ...
  numel(mat_sync_times) == numel(plex_sync_times), 'Sync times do not match.' );

roi_names = keys( roi_file.m1.rects );
comb_indices = combvec( 1:numel(roi_names) );

all_labs = fcat();
all_aligned_ib = [];

for idx = 1:size(comb_indices, 2)
  
  target_roi_name = roi_names{comb_indices(1, idx)};
  target_roi = roi_file.m1.rects(target_roi_name);

  allow_oob = false;
  edf_plex_time = edf_to_plex_time( edf_time, edf_sync_times, plex_sync_times, allow_oob );

  ib = bfw.bounds.rect( edf_x(:), edf_y(:), target_roi );

  sham_times = stim_file.sham_times(:);
  stim_times = stim_file.stimulation_times(:);

  stim_events = [ stim_times; sham_times ];
  stim_types = { 'stim', 'sham' };
  stim_type_indices = [ ones(numel(stim_times), 1); repmat(2, numel(sham_times), 1) ];

  aligned_ib = false( numel(stim_events), numel(t) );

  labs = fcat();

  for i = 1:numel(stim_events)
    start_t = stim_events(i) + lb;
    stop_t = stim_events(i) + la;

    [~, start_ind] = min( abs(edf_plex_time - start_t) );
    [~, stop_ind] = min( abs(edf_plex_time - stop_t) );

    c_n = stop_ind - start_ind + 1;
    use_n = min( c_n, numel(t) );

    aligned_ib(i, 1:use_n) = ib(start_ind:start_ind+use_n-1);

    append( labs, fcat.create(...
        'unified_filename', stim_file.unified_filename ...
      , 'session', un_file.m1.mat_directory_name ...
      , 'stim_type', stim_types{stim_type_indices(i)} ...
      , 'roi', target_roi_name ...
    ));
  end
  
  all_aligned_ib = [ all_aligned_ib; aligned_ib ];
  append( all_labs, labs );
end

end

function events_b = edf_to_plex_time(events_a, clock_a, clock_b, allow_oob)

events_b = nan( size(events_a) );

assert( ~allow_oob, 'Not yet implemented.' );

for i = 1:numel(events_a)
  t = events_a(i);
  
  [~, I] = min( abs(clock_a - t) );
  
  sync_a = clock_a(I);
  
  % times match exactly
  if ( sync_a == t )
    events_b(i) = clock_b(I);
    continue;
  end
  
  if ( t < sync_a )
    % target-time is earlier than sync time
    if ( I == 1 )
      if ( allow_oob )
        t1a = nan;
        t1b = nan;
      else
        continue;
      end
    else
      t1a = clock_a(I-1);
      t1b = clock_b(I-1);
    end
    
    t2a = clock_a(I);
    t2b = clock_b(I);
  else
    % target-time is after sync time
    t1a = clock_a(I);
    t1b = clock_b(I);
    
    if ( I == numel(clock_a) )
      if ( allow_oob )
        t2a = nan;
        t2b = nan;
      else
        continue;
      end
    else
      t2a = clock_a(I+1);
      t2b = clock_b(I+1);
    end
  end
  
  assert( ~(isnan(t1a) && isnan(t2a)), 'No sync times matched.' );
  
  frac = (t - t1a) / (t2a - t1a);
  
  events_b(i) = ((t2b - t1b) * frac) + t1b;
end

end