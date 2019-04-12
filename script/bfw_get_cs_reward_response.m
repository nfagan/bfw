function out = bfw_get_cs_reward_response(varargin)

defaults = bfw.get_common_make_defaults();
defaults.look_back = -0.5;
defaults.look_ahead = 0.5;
defaults.bin_size = 0.05;
defaults.event_names = { 'cs_presentation' };

inputs = { 'cs_labels/m1', 'cs_task_events/m1', 'cs_trial_data/m1' };
output = '';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
configure_loop_runner( loop_runner );

spike_p = bfw.gid( 'spikes', params.config );
meta_p = bfw.gid( 'meta', params.config );

results = loop_runner.run( @gather_per_run, spike_p, meta_p, params );

results(~[results.success]) = [];
out = struct();

if ( isempty(results) )
  out.psth = [];
  out.labels = fcat();
  out.t = [];
  out.reward_levels = [];
  
else
  outputs = [results.output];
  
  out.psth = vertcat( outputs.psth );
  out.labels = vertcat( fcat, outputs.labels );
  out.t = outputs(1).t;
  out.reward_levels = vertcat( outputs.reward_levels );
end

end

function out = gather_per_run(files, spike_p, meta_p, params)

cs_labels_file = shared_utils.general.get( files, 'cs_labels/m1' );
cs_events_file = shared_utils.general.get( files, 'cs_task_events/m1' );
cs_trial_data_file = shared_utils.general.get( files, 'cs_trial_data/m1' );

un_filename = bfw.try_get_unified_filename( cs_labels_file );

spike_file = get_spike_file( spike_p, un_filename );
meta_file = get_meta_file( meta_p, un_filename );

look_back = params.look_back;
look_ahead = params.look_ahead;
bin_size = params.bin_size;
event_names = cellstr( params.event_names );

units = spike_file.data;
[event_times, event_name_indices] = get_event_times( cs_events_file, event_names );

is_first = true;
stp = 1;

meta_labels = bfw.struct2fcat( meta_file );
psth_labels = fcat();

reward_levels = [];

for i = 1:numel(units)
  spike_ts = units(i).times;
  
  for j = 1:numel(event_times)
    event_time = event_times(j);
    
    if ( ~isnan(event_time) )
      [psth, t] = dsp3.psth( spike_ts, event_time, look_back, look_ahead, bin_size );

      if ( is_first )
        psth_mat = nan( numel(units) * size(event_times, 1), numel(t) );
        is_first = false;
      end
    
      psth_mat(stp, :) = psth;
    end
    
    stp = stp + 1;    
  end
  
  unit_labels = fcat.from( bfw.get_unit_labels(units(i)) );
  joined_labels = join( cs_labels_file.labels', unit_labels, meta_labels );
  bfw.unify_single_region_labels( joined_labels );
  
  add_event_name_labels( joined_labels, event_names, event_name_indices );
  
  append( psth_labels, joined_labels );
  
  for j = 1:numel(event_names)
    reward_levels = [ reward_levels; cs_trial_data_file.reward_levels ];
  end
end

out = struct();
out.psth = psth_mat;
out.labels = psth_labels;
out.reward_levels = reward_levels;
out.t = t;

end

function add_event_name_labels(joined_labels, event_names, event_name_indices)

repmat( joined_labels, numel(event_names) );
addcat( joined_labels, 'event-name' );

for i = 1:numel(event_names)
  event_ind = find( event_name_indices == i );
  setcat( joined_labels, 'event-name', event_names{i}, event_ind );
end

end

function [event_times, event_name_indices] = get_event_times(cs_events_file, event_names)

event_times = [];
event_name_indices = [];

n_events = size( cs_events_file.event_times, 1 );

for i = 1:numel(event_names)
  is_target_t = strcmp( cs_events_file.event_key, event_names{i} );

  assert( nnz(is_target_t) == 1, 'Missing "%s" key.', event_names{i} );

  event_times = [ event_times; cs_events_file.event_times(:, is_target_t) ];
  event_name_indices = [ event_name_indices; repmat(i, n_events, 1) ];
end

end

function configure_loop_runner(loop_runner)

bfw.make.util.configure_loop_runner_for_cs( loop_runner );
loop_runner.convert_to_non_saving_with_output();
loop_runner.func_name = mfilename;

end

function spike_file = get_spike_file(spike_p, unified_filename)

spike_file = shared_utils.io.fload( fullfile(spike_p, unified_filename) );

if ( spike_file.is_link )
  spike_file = shared_utils.io.fload( fullfile(spike_p, spike_file.data_file) );
end

end

function meta_file = get_meta_file(meta_p, unified_filename)

meta_file = shared_utils.io.fload( fullfile(meta_p, unified_filename) );

end
