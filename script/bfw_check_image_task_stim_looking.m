function bfw_check_image_task_stim_looking(varargin)

defaults = bfw.get_common_make_defaults();

inputs = { 'image_task_events', 'aligned_raw_samples/position' ...
  , 'aligned_raw_samples/time', 'unified', 'stim', 'stim_meta', 'meta' };
output = '';

[params, runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
runner.convert_to_non_saving_with_output();

results = runner.run( @check_bounds, params );

end

function out = check_bounds(files, params)

%%

un_file = shared_utils.general.get( files, 'unified' );
events_file = shared_utils.general.get( files, 'image_task_events' );
pos_file = shared_utils.general.get( files, 'position' );
t_file = shared_utils.general.get( files, 'time' );
stim_file = shared_utils.general.get( files, 'stim' );

stim_rects = arrayfun( @(x) x.stim_rect, un_file.m1.trial_data, 'un', 0 );
stim_rects = vertcat( stim_rects{:} );

image_on = events_file.m1.events(:, strcmp(events_file.event_key, 'image_onset'));
stim_times = [ stim_file.stimulation_times(:); stim_file.sham_times(:) ];

non_nan = find( ~isnan(t_file.t) );
stim_start_inds = non_nan( bfw.find_nearest(t_file.t(non_nan), stim_times) );

look_ahead = 2e3;
look_back = 0e3;
bounds = [];
denom = numel( stim_times );
bin_amt = 25;

t_course = shared_utils.vector.slidebin( look_back:look_ahead, bin_amt, bin_amt, true );
t_course = cellfun( @(x) x(1), t_course );

for i = 1:numel(stim_times)
  nearest_image = find( stim_times(i) > image_on, 1, 'last' );
  if ( isempty(nearest_image) )
    denom = denom - 1;
    continue;
  end
  
  t_course_ind = (stim_start_inds(i) + look_back):(stim_start_inds(i)+look_ahead);
  
  eye_rect = stim_rects(nearest_image, :);
  pad_w = (eye_rect(3) - eye_rect(1)) * 0.1;
  pad_h = (eye_rect(4) - eye_rect(2)) * 0.1;
  eye_rect(1) = eye_rect(1) - pad_w;
  eye_rect(3) = eye_rect(3) + pad_w;
  eye_rect(2) = eye_rect(2) - pad_h;
  eye_rect(4) = eye_rect(4) + pad_h;
  
  eye_pos = pos_file.m1(:, t_course_ind);
  ib = bfw.bounds.rect( eye_pos(1, :), eye_pos(2, :), eye_rect );
  ib = shared_utils.vector.slidebin( ib, bin_amt, bin_amt, true );
  
  bounds(i, :) = cellfun( @(x) any(x), ib );
end

plot( t_course, nansum(bounds, 1) / denom );

end