function outs = bfw_image_task_stim_fixations(varargin)

defaults = bfw.get_common_make_defaults();
defaults.rect_padding = 0.1;
defaults.min_dur = 30; % ms
defaults.look_ahead = 5e3;  % ms
defaults.use_image_offset = false;

inputs = { 'image_task_events', 'aligned_raw_samples/position' ...
  , 'aligned_raw_samples/time', 'aligned_raw_samples/raw_eye_mmv_fixations' ...
  , 'unified', 'stim', 'stim_meta', 'meta' };

[params, runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();

params.day_info_xls = get_day_info_xls( params.config );

results = runner.run( @main, params );
outputs = [ results([results.success]).output ];

outs = struct();
outs.params = params;

if ( isempty(outputs) )
  outs.labels = fcat();
  outs.fix_info = [];
  outs.relative_start_times = [];
  outs.next_fixation_start_times = [];
  outs.trial_starts = [];
  outs.image_offsets = [];
else
  outs.labels = vertcat( fcat, outputs.labels );
  outs.fix_info = vertcat( outputs.fix_info );
  outs.relative_start_times = vertcat( outputs.relative_start_times );
  outs.next_fixation_start_times = vertcat( outputs.next_fixation_start_times );
  outs.trial_starts = vertcat( outputs.trial_starts );
  outs.image_offsets = vertcat( outputs.image_offsets );
end

end

function outs = main(files, params)

import shared_utils.*;

un_file = general.get( files, 'unified' );
events_file = general.get( files, 'image_task_events' );
pos_file = general.get( files, 'position' );
t_file = general.get( files, 'time' );
stim_file = general.get( files, 'stim' );
fix_file = general.get( files, 'raw_eye_mmv_fixations' );

stim_rects = bfw_it.stim_rects_from_unified_file( un_file );

image_on_event_ind = strcmp(events_file.event_key, 'image_onset');
image_off_event_ind = strcmp(events_file.event_key, 'image_offset');

if ( nnz(image_off_event_ind) ~= 1 )
  error( 'Missing image offset event.' );
end

image_off = events_file.m1.events(:, image_off_event_ind);
image_off_inds = bfw_it.find_nearest_stim_time( t_file.t, image_off );
image_off_times = t_file.t(image_off_inds);

image_on = events_file.m1.events(:, image_on_event_ind);

stim_times = [ stim_file.stimulation_times(:); stim_file.sham_times(:) ];
stim_start_inds = bfw_it.find_nearest_stim_time( t_file.t, stim_times );
stim_times = t_file.t(stim_start_inds);

image_indices = nan( numel(stim_times), 1 );
trial_starts = nan( size(image_indices) );
image_offsets = nan( size(image_indices) );
fix_info = [];

min_t = min( t_file.t );

relative_starts = stim_times - min_t;
next_fix_start_times = nan( size(image_indices) );

for i = 1:numel(stim_times)
  nearest_image = find( stim_times(i) > image_on, 1, 'last' );
  last_offset = find( image_off_times > stim_times(i), 1, 'first' );
  
  assert( ~isempty(nearest_image), 'No image preceded stim.' );
  assert( ~isempty(last_offset), 'No image offset followed stim.' );
  
  last_offset_ind = image_off_inds(last_offset);
  
  eye_rect = bfw_it.pad_rect( stim_rects(nearest_image, :), params.rect_padding );
  
  x_pos = pos_file.m1(1, :);
  y_pos = pos_file.m1(2, :);
  
  ib = bfw.bounds.rect( x_pos, y_pos, eye_rect );
  ib_fix = ib & fix_file.m1;
  [fix_starts, fix_durs] = shared_utils.logical.find_all_starts( ib_fix );
  
  is_long_enough = fix_durs >= params.min_dur;
  
  if ( params.use_image_offset )
    if ( i < numel(stim_times) )
      stop_ind = min( stim_start_inds(i+1), last_offset_ind );
    else
      stop_ind = last_offset_ind;
    end
    
    is_within_t_bounds = fix_starts >= stim_start_inds(i) & ...
      fix_starts < stop_ind;
  else
    is_within_t_bounds = fix_starts >= stim_start_inds(i) & ...
      fix_starts < stim_start_inds(i) + params.look_ahead;
  end
  
  is_target_fix = is_long_enough & is_within_t_bounds;
  first_start = find( is_within_t_bounds, 1 );
  
  target_fix_starts = fix_starts(is_target_fix);
  target_fix_durs = fix_durs(is_target_fix);
  
  if ( isempty(first_start) )
    duration_next_fixation = nan;
    next_fix_start_times(i) = nan;
  else
    next_fix_start_times(i) = t_file.t(fix_starts(first_start)) - min_t;
    duration_next_fixation = fix_durs(first_start);
  end
  
  n_fix = numel( target_fix_starts );
  total_dur = sum( target_fix_durs );
  
  trial_starts(i) = image_on(nearest_image) - min_t;
  image_offsets(i) = image_off_times(nearest_image) - min_t;
  
  image_indices(i) = nearest_image;
%   fix_info(i, :) = [ numel(fix_starts), median(fix_durs) ];
  fix_info(i, :) = [ n_fix, total_dur, duration_next_fixation ];
end

labels = bfw_it.make_stim_labels( files, image_indices );
bfw_it.add_day_info_labels( labels, params.day_info_xls );

outs = struct();
outs.fix_info = fix_info;
outs.labels = labels;
outs.relative_start_times = relative_starts;
outs.next_fixation_start_times = next_fix_start_times;
outs.trial_starts = trial_starts;
outs.image_offsets = image_offsets;

end

function day_info = get_day_info_xls(conf)

day_info = bfw_it.process_day_info_xls( bfw_it.load_day_info_xls(conf) );

end