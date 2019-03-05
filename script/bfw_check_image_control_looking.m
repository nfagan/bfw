function outs = bfw_check_image_control_looking(varargin)

defaults = bfw.get_common_make_defaults();

conf = bfw.config.load();
conf.PATHS.data_root = '/Users/Nick/Desktop/bfw/';

defaults.config = conf;

inputs = { 'unified', 'sync' ...
  , 'aligned_raw_samples/position', 'aligned_raw_samples/time', 'meta' };

[~, runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();

results = runner.run( @looking_main );

outputs = [ results([results.success]).output ];

outs = struct();
outs.looking_duration = vertcat( outputs.looking_duration );
outs.labels = vertcat( fcat, outputs.labels );

end

function outs = looking_main(files)

un_file = shared_utils.general.get( files, 'unified' );
pos_file = shared_utils.general.get( files, 'position' );
time_file = shared_utils.general.get( files, 'time' );
sync_file = shared_utils.general.get( files, 'sync' );
meta_file = shared_utils.general.get( files, 'meta' );

trial_data = un_file.m1.trial_data;
delay_to_reward = un_file.m1.bsc_config.TIME_IN.delay_to_reward;

image_onsets = arrayfun( @(x) x.events.image_onset, trial_data );
image_offsets = arrayfun( ...
  @(x) x.events.inter_image_interval_reward_onset - delay_to_reward, trial_data );

mat_sync = sync_file.plex_sync(:, strcmp(sync_file.sync_key, 'mat'));
plex_sync = sync_file.plex_sync(:, strcmp(sync_file.sync_key, 'plex'));

pl2_image_onsets = bfw.clock_a_to_b( image_onsets, mat_sync, plex_sync );
pl2_image_offsets = bfw.clock_a_to_b( image_offsets, mat_sync, plex_sync );

t = time_file.t;
pos = pos_file.m1;

trial_categories = { 'image_condition', 'image_direction', 'image_identifier', 'image_monkey' };

meta_labels = bfw.struct2fcat( meta_file );
trial_labels = fcat.with( trial_categories );

looking_duration = nan( numel(pl2_image_onsets), 1 );

for i = 1:numel(pl2_image_onsets)
  onset = pl2_image_onsets(i);
  offset = pl2_image_offsets(i);
  
  t_ind = t >= onset & t <= offset;
  
  x = pos(1, t_ind);
  y = pos(2, t_ind);
  
  if ( isfield(trial_data(i), 'image_rect') )
    image_rect = get_rect( trial_data(i).image_rect );
  else
    image_rect = get_rect( trial_data(i).image );
  end
 
  is_in_bounds = bfw.bounds.rect( x, y, image_rect );
  looking_duration(i) = sum( is_in_bounds );
  
  image_identifier = trial_data(i).image_identifier;
  image_condition = trial_data(i).image_condition;
  image_condition_parts = strsplit( image_condition, '/' );
  
  image_monkey = image_condition_parts{1};
  image_direction = image_condition_parts{2};
  
  current_trial_labels = fcat();
  addsetcat( current_trial_labels, trial_categories ...
    , {image_condition, image_direction, image_identifier, image_monkey} );
  
  append( trial_labels, current_trial_labels );
end

join( trial_labels, meta_labels );

outs = struct();
outs.looking_duration = looking_duration;
outs.labels = trial_labels;

end