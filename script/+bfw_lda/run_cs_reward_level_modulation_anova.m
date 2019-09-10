function run_cs_reward_level_modulation_anova(reward_counts, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
params = bfw.parsestruct( defaults, varargin );

base_events = { 'iti', 'fixation' };
% targ_events = { 'cs_target_acquire', 'cs_delay', 'cs_reward' };
% targ_events = event_combinations( targ_events );
% targ_events = { 'cs_target_acquire', 'cs_reward' };
% targ_events = { 'cs_target_acquire', 'cs_presentation', 'cs_reward', 'cs_delay' };
% targ_events = { 'cs_delay' };
% targ_events = { {'cs_target_acquire', 'cs_delay'} };
is_normalized_combs = true;
targ_events = { {'cs_target_acquire', 'cs_delay', 'cs_reward'} };

cmbs = dsp3.numel_combvec( base_events, targ_events, is_normalized_combs );

for i = 1:size(cmbs, 2)

shared_utils.general.progress( i, size(cmbs, 2) );

base_event = base_events{cmbs(1, i)};
targ_event = targ_events{cmbs(2, i)};
is_normalized = is_normalized_combs(cmbs(3, i));

if ( ~is_normalized && cmbs(1, i) > 1 )
  % Skip different baseline periods when not-normalizing
  continue;
end

if ( iscell(targ_event) )
  targ_event_str = strjoin( targ_event, '_' );
else
  targ_event_str = targ_event;
end

base_subdir = sprintf( '%s%s/', params.base_subdir, targ_event_str );
base_subdir = sprintf( '%s_%s_baseline', base_subdir, base_event );

if ( iscell(targ_event) && numel(targ_event) > 1 )
  targ_ts = cellfun( @time_window_for_event, targ_event, 'un', 0 );
  targ_t = cell2struct( targ_ts, targ_event, 2 );
  t_str = strjoin( cellfun(@(x) sprintf('%d_%d', x * 1e3), targ_ts, 'un', 0), '__' );
else
  targ_ts = time_window_for_event( targ_event );
  targ_t = struct( targ_event, targ_ts );
  t_str = sprintf( '%d_%d', targ_ts * 1e3 );
end

base_t = time_window_for_event( base_event );

if ( is_normalized )
  base_subdir = sprintf( '%s_norm', base_subdir );
else
  base_subdir = sprintf( '%s_non_norm', base_subdir );
end

base_subdir = sprintf( '%s_%s', base_subdir, t_str );

bfw_lda.cs_reward_level_modulation_anova( ...
    params ...
  , 'reward_counts', reward_counts ...
  , 'targ_event', targ_event ...
  , 'targ_t', targ_t ...
  , 'base_event', base_event ...
  , 'base_t', base_t ...
  , 'do_save', true ...
  , 'base_subdir', base_subdir ...
  , 'lda_rng_seed', 0 ...
  , 'is_normalized', is_normalized ...
  , 'min_trials_per_condition', 5 ...
);

end

end

function t = time_window_for_event(event_name)

switch ( event_name )
  case 'cs_reward'
    t = [0.05, 0.6];
  case 'cs_target_acquire'
    t = [-0.25, 0];
  case 'cs_presentation'
    t = [0.05, 0.4];
  case 'fixation'
    t = [0, 0.15];
  case 'iti'
    t = [0.5, 1];
  case 'cs_delay'
    t = [0, 0.25];
  otherwise
    error( 'Unrecognized target event: "%s".', targ_event );
end

end

function C = event_combinations(events)

if ( numel(events) <= 1 )
  C = events;
  return
end

C = cell( 1, numel(events)-1 );

for i = 2:numel(events)
  ind = nchoosek( 1:numel(events), i );
  tmp = cell( 1, size(ind, 1) );
  for j = 1:size(ind, 1)
    tmp{j} = events(ind(j, :));
  end
  C{i-1} = tmp;
end

C = horzcat( C{:} );

end