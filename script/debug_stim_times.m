function [outs, plot_t, params] = debug_stim_times(varargin)

import shared_utils.io.fload;

ff = @fullfile;

defaults = bfw.get_common_make_defaults();
defaults.look_ahead = 5;
defaults.look_back = -1;
defaults.roi_pad = 0;

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;

unified_p =     bfw.gid( ff('unified', isd), conf );
stim_p =        bfw.gid( ff('stim', isd), conf );
mat_sync_p =    bfw.gid( ff('sync', isd), conf );
edf_samples_p = bfw.gid( ff('edf_raw_samples', isd), conf );
edf_sync_p =    bfw.gid( ff('edf_sync', isd), conf );
roi_p =         bfw.gid( ff('rois', isd), conf );

look_ahead = params.look_ahead;
look_back = params.look_back;
fs = 1/1e3;

plot_t = look_back:fs:look_ahead;

mats = bfw.require_intermediate_mats( params.files, stim_p, params.files_containing );

all_ib = cell( size(mats) );
all_is_fix = cell( size(mats) );
all_labs = cell( size(mats) );
all_x = cell( size(mats) );
all_y = cell( size(mats) );
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
  process_params.roi_pad = params.roi_pad;

  try 
    outs = one_file( un_file, stim_file, mat_sync_file, edf_sync_file ...
      , edf_samples_file, roi_file, process_params );
  catch err
    warning( '"%s" (%d) failed with message: "%s"', unified_filename, i, err.message );
    is_ok(i) = false;
    continue;
  end
  
  try
    all_ib{i} = outs.ib;
    all_is_fix{i} = outs.is_fix;
    all_labs{i} = outs.labs;
    all_x{i} = outs.x;
    all_y{i} = outs.y;
  catch err
    warning( '"%s" (%d) failed with message: "%s"', unified_filename, i, err.message );
    is_ok(i) = false;
    continue;
  end
end

all_ib(~is_ok) = [];
all_is_fix(~is_ok) = [];
all_labs(~is_ok) = [];
all_x(~is_ok) = [];
all_y(~is_ok) = [];

ib = vertcat( all_ib{:} );
is_fix = vertcat( all_is_fix{:} );
x = vertcat( all_x{:} );
y = vertcat( all_y{:} );
labs = vertcat( fcat(), all_labs{:} );

outs = struct();
outs.labs = labs;
outs.x = x;
outs.y = y;
outs.ib = ib;
outs.is_fix = is_fix;

end

function outs = one_file(un_file, stim_file, mat_sync_file, edf_sync_file, edf_samples_file, roi_file, params)

lb = params.look_back;
la = params.look_ahead;
t = params.time;
pad = params.roi_pad;

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
all_is_fixation = [];
all_aligned_x = [];
all_aligned_y = [];

dispersion_checker = bfw.fixation.Dispersion( 20, 4, 1 );
is_fix = dispersion_checker.detect( edf_x, edf_y );

un_filename = stim_file.unified_filename;
session_dir = un_file.m1.mat_directory_name;
task_type = bfw.field_or( un_file.m1, 'task_type', 'free_viewing' );

for idx = 1:size(comb_indices, 2)
  
  target_roi_name = roi_names{comb_indices(1, idx)};
  target_roi = bfw.bounds.rect_pad_frac( roi_file.m1.rects(target_roi_name), pad, pad );

  edf_plex_time = shared_utils.sync.cinterp( edf_time, edf_sync_times, plex_sync_times );

  ib = bfw.bounds.rect( edf_x(:), edf_y(:), target_roi );

  sham_times = stim_file.sham_times(:);
  stim_times = stim_file.stimulation_times(:);

  stim_events = [ stim_times; sham_times ];
  stim_types = { 'stim', 'sham' };
  stim_type_indices = [ ones(numel(stim_times), 1); repmat(2, numel(sham_times), 1) ];

  aligned_ib = false( numel(stim_events), numel(t) );
  aligned_is_fix = false( size(aligned_ib) );
  
  labs = fcat();

  for i = 1:numel(stim_events)
    start_t = stim_events(i) + lb;
    stop_t = stim_events(i) + la;

    [~, start_ind] = min( abs(edf_plex_time - start_t) );
    [~, stop_ind] = min( abs(edf_plex_time - stop_t) );

    c_n = stop_ind - start_ind + 1;
    use_n = min( c_n, numel(t) );
    
    index_vec = start_ind:start_ind+use_n-1;

    aligned_ib(i, 1:use_n) = ib(index_vec);
    aligned_is_fix(i, 1:use_n) = is_fix(index_vec);
    aligned_x(i, 1:use_n) = edf_x(index_vec);
    aligned_y(i, 1:use_n) = edf_y(index_vec);

    append( labs, fcat.create( ...
        'unified_filename',   un_filename ...
      , 'session',            session_dir ...
      , 'stim_type',          stim_types{stim_type_indices(i)} ...
      , 'roi',                target_roi_name ...
      , 'task_type',          task_type ...
    ));
  end
  
  all_aligned_ib = [ all_aligned_ib; aligned_ib ];
  all_is_fixation = [ all_is_fixation; aligned_is_fix ];
  all_aligned_x = [ all_aligned_x; aligned_x ];
  all_aligned_y = [ all_aligned_y; aligned_y ];
  
  append( all_labs, labs );
end

outs.labs = all_labs;
outs.ib = all_aligned_ib;
outs.x = all_aligned_x;
outs.y = all_aligned_y;
outs.is_fix = all_is_fixation;

end