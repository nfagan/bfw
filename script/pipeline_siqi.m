folders = {};
file_spec = folders;

conf = bfw.config.load();
conf.PATHS.data_root = '/mnt/dunham/media/chang/T2/data/bfw-siqi';

input_subdir = '';
output_subdir = '';

siqi_id = '';
do_overwrite = true;

shared_inputs = { 'config', conf, 'input_subdir', input_subdir, 'output_subdir', output_subdir ...
  , 'files_containing', file_spec, 'overwrite', do_overwrite };

%%  fixations

bfw.make_eye_mmv_fixations( shared_inputs{:} ...
  , 't1', 20 ...
  , 't2', 10 ...
  , 'min_duration', 0.03 ...
);

%%  restrict fixations to at least N ms

bfw.adjust.set_fixation_criterion( shared_inputs{:} ...
  , 'duration', 10 ... % remove fixations less than n ms.
  , 'output_subdir', siqi_id ... %   output dir
);

%%  rois

bfw.make_rois( shared_inputs{:} ...
  , 'output_subdir', siqi_id ... %   output dir
);

%%  bounds

bfw.make_bounds( shared_inputs{:} ...
  , 'window_size', 10 ...
  , 'step_size', 10 ...
  , 'remove_blink_nans', false ...
  , 'require_fixation', true ...
  , 'single_roi_fixations', false ...
  , 'input_subdir',  siqi_id ...  %   input dir
  , 'output_subdir', siqi_id ... %   output dir
);

%   separate eyes from face
bfw.adjust.separate_eyes_from_face( shared_inputs{:} );

%%  events

bfw.make_events( shared_inputs{:} ...
  , 'mutual_method', 'duration' ...
  , 'duration', 10 ...  %   minimum event duration (ms)
  , 'fill_gaps', true ...   
  , 'fill_gaps_duration', 150 ... % fill true within N (ms)
  , 'input_subdir', siqi_id ...  %   input dir
  , 'output_subdir', siqi_id ... %   output dir
);

%   convert to plexon time
bfw.adjust.events_to_plex_time( shared_inputs{:} ...
      , 'input_subdir', siqi_id ...  %   input dir
      , 'output_subdir', siqi_id ... %   output dir
);

%   concatenate events within day
bfw.make_events_per_day( shared_inputs{:} ...
      , 'input_subdir', siqi_id ...  %   input dir
      , 'output_subdir', siqi_id ... %   output dir
);