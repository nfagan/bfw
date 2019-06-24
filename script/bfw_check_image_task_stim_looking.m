function outs = bfw_check_image_task_stim_looking(varargin)

defaults = bfw.get_common_make_defaults();
defaults.look_back = -1e3;
defaults.look_ahead = 1e3;
defaults.bin_size = 25;
defaults.rect_padding = 0.1;
defaults.bin_func = @any;

inputs = { 'image_task_events', 'aligned_raw_samples/position' ...
  , 'aligned_raw_samples/time', 'aligned_raw_samples/raw_eye_mmv_fixations' ...
  , 'unified', 'stim', 'stim_meta', 'meta' };

[params, runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();

results = runner.run( @check_bounds, params );
outputs = [ results([results.success]).output ];

outs = struct();
outs.params = params;

if ( isempty(outputs) )
  outs.t = [];
  outs.labels = fcat();
  outs.bounds = [];
  outs.relative_start_times = [];
else
  outs.t = outputs(1).t;
  outs.labels = vertcat( fcat, outputs.labels );
  outs.bounds = vertcat( outputs.bounds );
  outs.relative_start_times = vertcat( outputs.relative_start_times );
end

end

function outs = check_bounds(files, params)

import shared_utils.*;

un_file = general.get( files, 'unified' );
events_file = general.get( files, 'image_task_events' );
pos_file = general.get( files, 'position' );
t_file = general.get( files, 'time' );
stim_file = general.get( files, 'stim' );

stim_rects = bfw_it.stim_rects_from_unified_file( un_file );
image_rects = bfw_it.image_rects_from_unified_file( un_file );

image_on = events_file.m1.events(:, strcmp(events_file.event_key, 'image_onset'));
stim_times = [ stim_file.stimulation_times(:); stim_file.sham_times(:) ];
stim_start_inds = bfw_it.find_nearest_stim_time( t_file.t, stim_times );

look_ahead = params.look_ahead;
look_back = params.look_back;
bin_amt = params.bin_size;

t_course = shared_utils.vector.slidebin( look_back:look_ahead, bin_amt, bin_amt, true );
t_course = cellfun( @(x) x(1), t_course );

bounds = zeros( numel(stim_times), numel(t_course) );
image_indices = nan( numel(stim_times), 1 );
relative_start_times = stim_times - min( t_file.t );

for i = 1:numel(stim_times)
  nearest_image = find( stim_times(i) > image_on, 1, 'last' );
  assert( ~isempty(nearest_image), 'No image preceded stim.' );
  
  t_course_ind = (stim_start_inds(i) + look_back):(stim_start_inds(i)+look_ahead);
  left_over = numel( t_file.t ) - max( t_course_ind );
  
  if ( left_over < 0 )
    t_course_ind(t_course_ind > numel(t_file.t)) = [];
  end
  
  eye_rect = bfw_it.pad_rect( stim_rects(nearest_image, :), params.rect_padding );
  
  eye_pos = pos_file.m1(:, t_course_ind);
  ib = bfw.bounds.rect( eye_pos(1, :), eye_pos(2, :), eye_rect );
  ib = shared_utils.vector.slidebin( ib, bin_amt, bin_amt, true );
  
  tmp_bounds = cellfun( @(x) params.bin_func(double(x)), ib );
  
  if ( numel(tmp_bounds) < numel(t_course) )
    tmp_bounds(end+1:numel(t_course)) = 0;
  end
  
  bounds(i, :) = tmp_bounds;
  image_indices(i) = nearest_image;  
end

labels = bfw_it.make_stim_labels( files, image_indices );

outs = struct();
outs.t = t_course;
outs.bounds = bounds;
outs.labels = labels;
outs.relative_start_times = relative_start_times;

end