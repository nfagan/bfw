%%

num_session_bins = 10;

all_files = shared_utils.io.findmat( bfw.gid('raw_events_remade') );
all_files = shared_utils.io.filenames( all_files, true );
sessions = cellfun( @(x) x(1:8), all_files, 'un', 0 );
unique_sessions = unique( sessions );
binned_sessions = shared_utils.vector.distribute( 1:numel(unique_sessions), num_session_bins );
binned_sessions = cellfun( @(x) unique_sessions(x), binned_sessions, 'un', 0 );

bin_size = 1e-2;
step_size = 1e-2; % 10ms
look_back = -0.5;
look_ahead = 0.5;

save_p = 'C:\data\bfw\psth\fig1_psths';

for i = 1:numel(binned_sessions)
  shared_utils.general.progress( i, numel(binned_sessions) );

  seshs = binned_sessions{i};
  sesh_ind = ismember( sessions, seshs );

  select_files = all_files(sesh_ind);
  
  res = bfw_make_psth_for_fig1( ...
      'is_parallel', true ...
    , 'window_size', bin_size ...
    , 'step_size', step_size ...
    , 'look_back', look_back ...
    , 'look_ahead', look_ahead ...
    , 'files_containing', select_files(:)' ...
    , 'include_rasters', false ...
    , 'collapse_nonsocial_object_rois', true ...
  );

  gaze_counts = res.gaze_counts;
  fname = sprintf( '%s_%s.mat', binned_sessions{i}{1}, binned_sessions{i}{end} );
  shared_utils.io.require_dir( save_p );
  save( fullfile(save_p, fname), 'gaze_counts', '-v7.3' );
end