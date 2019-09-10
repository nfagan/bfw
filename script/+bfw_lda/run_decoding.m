function run_decoding(gaze_counts, reward_counts, varargin)

defaults = bfw.get_common_make_defaults();
defaults.base_subdir = '';
defaults.reward_t_window = [-0.25, 0];
defaults.is_over_time = false;

params = bfw.parsestruct( defaults, varargin );

data_p = get_data_p( params.config );
save_p = fullfile( data_p, 'performance', dsp3.datedir, params.base_subdir );

if ( nargin < 2 || isempty(reward_counts) )
  reward_counts = shared_utils.io.fload( fullfile(data_p, 'reward_counts.mat') );
end

if ( nargin < 1 || isempty(gaze_counts) )
  gaze_counts = shared_utils.io.fload( fullfile(data_p, 'gaze_counts.mat') );
end

%%

gaze_mask = get_gaze_mask( gaze_counts.labels );
reward_mask = get_reward_mask( reward_counts.labels );

common_inputs = struct();
common_inputs.base_reward_mask = reward_mask;
common_inputs.base_gaze_mask = gaze_mask;
common_inputs.n_iters = 100;
common_inputs.match_trials = false;
common_inputs.match_units = true;
common_inputs.reward_t_window = params.reward_t_window;

is_over_time = params.is_over_time;

%%

% gr_outs = train_gaze_test_reward( gaze_counts, reward_counts, common_inputs, is_over_time );
gr_outs = [];

%%

% rg_outs = train_reward_test_gaze( gaze_counts, reward_counts, common_inputs, is_over_time );
rg_outs = [];

%%

gg_outs = train_gaze_test_gaze( gaze_counts, reward_counts, common_inputs, is_over_time );
% gg_outs = [];

%%

% rr_outs = train_reward_test_reward( gaze_counts, reward_counts, common_inputs, is_over_time );
rr_outs = [];

%%

shared_utils.io.require_dir( save_p );
save( fullfile(save_p, 'performance.mat'), 'gr_outs', 'rg_outs', 'gg_outs', 'rr_outs' );

end

function decode_outs = train_reward_test_reward(gaze_counts, reward_counts, common_inputs, is_over_time)

if ( is_over_time )
  common_inputs.reward_t_window = get_reward_time_windows( reward_counts.t );
  common_inputs.is_train_x_test_x_timecourse = true;
end

rwd_levels = [ 1, 2, 3 ];
rwd_level_pairs = nchoosek( 1:numel(rwd_levels), 2 );

perf = [];
perf_labels = fcat();

for i = 1:size(rwd_level_pairs, 1)
  rwd0 = rwd_level_pairs(i, 1);
  rwd1 = rwd_level_pairs(i, 2);
  
  decode_outs = bfw_lda.population_decode_gaze_from_reward( gaze_counts, reward_counts ...
    , 'train_on', 'reward' ...
    , 'test_on', 'reward' ...
    , 'reward_level0', rwd0 ...
    , 'reward_level1', rwd1 ...
    , common_inputs ...
  );

  labels = decode_outs.labels;
  label_reward_levels( labels, rwd0, rwd1 );
  
  append( perf_labels, labels );
  perf = [ perf; decode_outs.performance ];
end

decode_outs.performance = perf;
decode_outs.labels = perf_labels;

end

function decode_outs = train_gaze_test_gaze(gaze_counts, reward_counts, common_inputs, is_over_time)

if ( is_over_time )
  common_inputs.gaze_t_window = get_gaze_time_windows( gaze_counts.t );
end

decode_outs = bfw_lda.population_decode_gaze_from_reward( gaze_counts, reward_counts ...
  , 'train_on', 'gaze' ...
  , 'test_on', 'gaze' ...
  , common_inputs ...
);

end

function decode_outs = train_reward_test_gaze(gaze_counts, reward_counts, common_inputs, is_over_time)

if ( is_over_time )
  common_inputs.gaze_t_window = get_gaze_time_windows( gaze_counts.t );
end

decode_outs = bfw_lda.population_decode_gaze_from_reward( gaze_counts, reward_counts ...
  , 'train_on', 'reward' ...
  , 'test_on', 'gaze' ...
  , common_inputs ...
);

end

function decode_outs = train_gaze_test_reward(gaze_counts, reward_counts, common_inputs, is_over_time)

if ( is_over_time )
  common_inputs.reward_t_window = get_reward_time_windows( reward_counts.t );
end

decode_outs = bfw_lda.population_decode_gaze_from_reward( gaze_counts, reward_counts ...
  , 'train_on', 'gaze' ...
  , 'test_on', 'reward' ...
  , common_inputs ...
);

end

function data_p = get_data_p(conf)

data_p = fullfile( bfw.dataroot(conf), 'analyses', 'spike_lda', 'reward_gaze_spikes' );

end

function label_reward_levels(labels, rwd0, rwd1)

reward_str = combs( labels, 'reward-level' );
assert( numel(reward_str) == 1 );

split = strsplit( reward_str{1}, '/' );
split{1} = strrep( split{1}, '0', num2str(rwd0) );
split{2} = strrep( split{2}, '1', num2str(rwd1) );

setcat( labels, 'reward-level', strjoin(split, '/') );

end

function gaze_mask = get_gaze_mask(labels)

gaze_mask = fcat.mask( labels ...
  , @find, 'm1' ...
  , @find, {'eyes_nf', 'face', 'nonsocial_object'} ...
);

end

function reward_mask = get_reward_mask(labels)

reward_mask = fcat.mask( labels ...
  , @findnone, 'iti' ...
);

end

function t_windows = get_time_windows(t, ws)

starts = t;
stops = t + ws;

too_big = stops > max( t );

starts = starts(~too_big);
stops = stops(~too_big);

t_windows = arrayfun( @(x, y) [x, y], starts, stops, 'un', false );

end

function t_windows = get_reward_time_windows(t)

t_windows = get_time_windows( t, 0.15 );

end

function t_windows = get_gaze_time_windows(t)

t_windows = get_time_windows( t, 0.15 );

end