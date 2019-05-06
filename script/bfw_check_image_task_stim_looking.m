function outs = bfw_check_image_task_stim_looking(varargin)

defaults = bfw.get_common_make_defaults();
defaults.look_back = -1e3;
defaults.look_ahead = 1e3;
defaults.bin_size = 25;
defaults.rect_padding = 0.1;

inputs = { 'image_task_events', 'aligned_raw_samples/position' ...
  , 'aligned_raw_samples/time', 'unified', 'stim', 'stim_meta', 'meta' };
output = '';

[params, runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
runner.convert_to_non_saving_with_output();

results = runner.run( @check_bounds, params );
outputs = [ results([results.success]).output ];

outs = struct();
outs.params = params;

if ( isempty(outputs) )
  outs.t = [];
  outs.labels = fcat();
  outs.bounds = logical( [] );
else
  outs.t = outputs(1).t;
  outs.labels = vertcat( fcat, outputs.labels );
  outs.bounds = vertcat( outputs.bounds );
end

end

function outs = check_bounds(files, params)

%%
un_file = shared_utils.general.get( files, 'unified' );
events_file = shared_utils.general.get( files, 'image_task_events' );
pos_file = shared_utils.general.get( files, 'position' );
t_file = shared_utils.general.get( files, 'time' );
stim_file = shared_utils.general.get( files, 'stim' );
meta_file = shared_utils.general.get( files, 'meta' );
stim_meta_file = shared_utils.general.get( files, 'stim_meta' );

stim_rects = arrayfun( @(x) x.stim_rect, un_file.m1.trial_data, 'un', 0 );
stim_rects = vertcat( stim_rects{:} );

image_on = events_file.m1.events(:, strcmp(events_file.event_key, 'image_onset'));
stim_times = [ stim_file.stimulation_times(:); stim_file.sham_times(:) ];

non_nan = find( ~isnan(t_file.t) );
stim_start_inds = non_nan( bfw.find_nearest(t_file.t(non_nan), stim_times) );

look_ahead = params.look_ahead;
look_back = params.look_back;
bin_amt = params.bin_size;

t_course = shared_utils.vector.slidebin( look_back:look_ahead, bin_amt, bin_amt, true );
t_course = cellfun( @(x) x(1), t_course );

bounds = false( numel(stim_times), numel(t_course) );
image_indices = nan( numel(stim_times), 1 );

for i = 1:numel(stim_times)
  nearest_image = find( stim_times(i) > image_on, 1, 'last' );
  assert( ~isempty(nearest_image), 'No image preceded stim.' );
  
  t_course_ind = (stim_start_inds(i) + look_back):(stim_start_inds(i)+look_ahead);
  left_over = numel( t_file.t ) - max( t_course_ind );
  
  if ( left_over < 0 )
    t_course_ind(t_course_ind > numel(t_file.t)) = [];
  end
  
  eye_rect = pad_rect( stim_rects(nearest_image, :), params.rect_padding );
  
  eye_pos = pos_file.m1(:, t_course_ind);
  ib = bfw.bounds.rect( eye_pos(1, :), eye_pos(2, :), eye_rect );
  ib = shared_utils.vector.slidebin( ib, bin_amt, bin_amt, true );
  
  tmp_bounds = cellfun( @(x) any(x), ib );
  
  if ( numel(tmp_bounds) < numel(t_course) )
    tmp_bounds(end+1:numel(t_course)) = false;
  end
  
  bounds(i, :) = tmp_bounds;
  image_indices(i) = nearest_image;
end

labels = make_labels( meta_file, stim_meta_file, stim_file, un_file.m1.trial_data, image_indices );

outs = struct();
outs.t = t_course;
outs.bounds = bounds;
outs.labels = labels;

end

function labels = make_labels(meta_file, stim_meta_file, stim_file, trial_data, image_indices)

n_stim_times = numel( stim_file.stimulation_times ) + numel( stim_file.sham_times );

labels = repmat( bfw.struct2fcat(meta_file), n_stim_times );
stim_meta_labels = bfw.stim_meta_to_fcat( stim_meta_file );
join( labels, stim_meta_labels );

add_stim_type_labels( labels, stim_file );

image_ids = { trial_data(image_indices).image_identifier };

addcat( labels, 'image_id' );
setcat( labels, 'image_id', image_ids );

prune( labels );

end

function add_stim_type_labels(labels, stim_file)

n_stim = numel( stim_file.stimulation_times );
n_sham = numel( stim_file.sham_times );
assert( rows(labels) == n_stim + n_sham );

addcat( labels, 'stim_type' );
setcat( labels, 'stim_type', 'stim', 1:n_stim );
setcat( labels, 'stim_type', 'sham', n_stim+1:rows(labels) );

end

function rect = pad_rect(rect, amount)

pad_w = (rect(3) - rect(1)) * amount;
pad_h = (rect(4) - rect(2)) * amount;

rect(1) = rect(1) - pad_w/2;
rect(3) = rect(3) + pad_w/2;
rect(2) = rect(2) - pad_h/2;
rect(4) = rect(4) + pad_h/2;

end