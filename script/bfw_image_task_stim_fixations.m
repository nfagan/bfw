function outs = bfw_image_task_stim_fixations(varargin)

defaults = bfw.get_common_make_defaults();
defaults.rect_padding = 0.1;
defaults.min_dur = 30; % ms
defaults.look_ahead = 5e3;  % ms

inputs = { 'image_task_events', 'aligned_raw_samples/position' ...
  , 'aligned_raw_samples/time', 'aligned_raw_samples/raw_eye_mmv_fixations' ...
  , 'unified', 'stim', 'stim_meta', 'meta' };

[params, runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();

results = runner.run( @main, params );
outputs = [ results([results.success]).output ];

outs = struct();
outs.params = params;

if ( isempty(outputs) )
  outs.labels = fcat();
  outs.fix_info = [];
else
  outs.labels = vertcat( fcat, outputs.labels );
  outs.fix_info = vertcat( outputs.fix_info );
end

end

function outs = main(files, params)
%%
import shared_utils.*;

un_file = general.get( files, 'unified' );
events_file = general.get( files, 'image_task_events' );
pos_file = general.get( files, 'position' );
t_file = general.get( files, 'time' );
stim_file = general.get( files, 'stim' );
fix_file = general.get( files, 'raw_eye_mmv_fixations' );

stim_rects = bfw_it.stim_rects_from_unified_file( un_file );

image_on = events_file.m1.events(:, strcmp(events_file.event_key, 'image_onset'));
stim_times = [ stim_file.stimulation_times(:); stim_file.sham_times(:) ];
stim_start_inds = bfw_it.find_nearest_stim_time( t_file.t, stim_times );

image_indices = nan( numel(stim_times), 1 );
fix_info = nan( numel(stim_times), 2 );

for i = 1:numel(stim_times)
  nearest_image = find( stim_times(i) > image_on, 1, 'last' );
  assert( ~isempty(nearest_image), 'No image preceded stim.' );
  
  eye_rect = bfw_it.pad_rect( stim_rects(nearest_image, :), params.rect_padding );
  
  x_pos = pos_file.m1(1, :);
  y_pos = pos_file.m1(2, :);
  
  ib = bfw.bounds.rect( x_pos, y_pos, eye_rect );
  ib_fix = ib & fix_file.m1;
  [fix_starts, fix_durs] = shared_utils.logical.find_all_starts( ib_fix );
  
  is_long_enough = fix_durs >= params.min_dur;
  is_within_t_bounds = fix_starts >= stim_start_inds(i) & ...
    fix_starts < stim_start_inds(i) + params.look_ahead;
  
  is_target_fix = is_long_enough & is_within_t_bounds;
  
  fix_starts = fix_starts(is_target_fix);
  fix_durs = fix_durs(is_target_fix);
  
  image_indices(i) = nearest_image;
  fix_info(i, :) = [ numel(fix_starts), median(fix_durs) ];
end

labels = bfw_it.make_stim_labels( files, image_indices );

outs = struct();
outs.fix_info = fix_info;
outs.labels = labels;

end