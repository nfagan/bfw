function results = make_raw_fixations(kind, varargin)

validateattributes( kind, {'char'}, {'scalartext'}, mfilename, 'kind' );

switch ( kind )
  case 'raw_eye_mmv_fixations'
    is_fix_func = @eye_mmv_is_fixation;
  case 'raw_arduino_fixations'
    is_fix_func = @arduino_is_fixation;
  otherwise
    error( 'Unrecognized kind "%s".', kind );
end

defaults = bfw.get_common_make_defaults();

% eye mmv defaults
defaults.min_duration = 0.01;
defaults.t1 = 30;
defaults.t2 = 15;

% arduio defaults
defaults.threshold = 20;
defaults.n_samples = 4;
defaults.update_interval = 1;

inputs = 'edf_raw_samples';
output = kind;

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

params.kind = kind;

results = loop_runner.run( @make_raw_fixations_main, is_fix_func, params );

end

function fix_file = make_raw_fixations_main(files, is_fix_func, params)

samples_file = shared_utils.general.get( files, 'edf_raw_samples' );
unified_filename = bfw.try_get_unified_filename( samples_file );

monks = { 'm1', 'm2' };

fix_file = struct();
fix_file.unified_filename = unified_filename;
fix_file.params = params;

for j = 1:numel(monks)    
  monk = monks{j};

  if ( ~isfield(samples_file, monk) ), continue; end

  x = samples_file.(monk).x;
  y = samples_file.(monk).y;

  time = samples_file.(monk).t;

  is_fix = is_fix_func( x, y, time, params );

  [starts, lengths] = shared_utils.logical.find_all_starts( is_fix );

  stops = starts + lengths - 1;

  fix_file.(monk).time = time;
  fix_file.(monk).is_fixation = is_fix;
  fix_file.(monk).start_indices = starts;
  fix_file.(monk).stop_indices = stops;
end

end

function is_fix = arduino_is_fixation(x, y, time, params)

ui = params.update_interval;
thresh = params.threshold;
nsamp = params.n_samples;

dispersion = bfw.fixation.Dispersion( thresh, nsamp, ui );

is_fix = dispersion.detect( x, y );

end

function is_fix = eye_mmv_is_fixation(x, y, time, params)

pos = [ x(:)'; y(:)' ];

t1 = params.t1;
t2 = params.t2;
min_duration = params.min_duration;

%   repositories/eyelink/eye_mmv
is_fix = is_fixation( pos, time(:)', t1, t2, min_duration );
is_fix = logical( is_fix );
is_fix = is_fix(1:numel(time))';

end