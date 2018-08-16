function make_per_trial_mua(varargin)

ff = @fullfile;

defaults = bfw.get_common_make_defaults();
defaults.look_back = -0.5;
defaults.look_ahead = 0.5;
defaults.step_size = 0.05;
defaults.window_size = 0.15;

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;
osd = params.output_subdir;

mua_p = bfw.gid( ff('mua_spikes', isd), conf );
events_p = bfw.gid( ff('events_per_day', isd), conf );
output_p = bfw.gid( ff('per_trial_mua', osd), conf );

lb = params.look_back;
la = params.look_ahead;
ws = params.window_size;
ss = params.step_size;

mats = bfw.require_intermediate_mats( params.files, mua_p, params.files_containing );

for i = 1:numel(mats)
  bfw.progress( i, numel(mats), mfilename );
  
  spike_file = shared_utils.io.fload( mats{i} );
  un_filename = spike_file.unified_filename;
  
  event_file = shared_utils.io.fload( fullfile(events_p, un_filename) );
  
  output_filename = fullfile( output_p, un_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  units = spike_file.data;
  evt_times = event_file.event_info.data(:, event_file.event_info_key('times'));
  evt_labs = event_file.event_info.labels;
  
  all_binned_units = cell( 1, numel(units) );
  all_channels = cell( numel(units), 1 );
  all_tseries = cell( numel(units), 1 );
  
  parfor j = 1:numel(units)
    fprintf( '\n\t %d of %d', j, numel(units) );
    
    unit = units(j);
    
    [binned_units, all_tseries{j}] = align_one_unit( unit.times, evt_times, lb, la, ws, ss );
    
    unit_labs = add_field( evt_labs, 'channel' );
    unit_labs = add_field( unit_labs, 'region' );
    unit_labs = set_field( unit_labs, 'region', unit.region{1} );
    unit_labs = set_field( unit_labs, 'channel', unit.channel_str );
    
    channels = repmat( unit.channel, shape(unit_labs, 1), 1 );
    
    all_channels{j} = channels;
    all_binned_units{j} = Container( binned_units, unit_labs );
  end
  
  spk_struct = struct();
  spk_struct.unified_filename = un_filename;
  spk_struct.data = Container.concat( all_binned_units );
  spk_struct.channels = cell2mat( all_channels );
  spk_struct.time = all_tseries{1};
  spk_struct.params = params;
  
  shared_utils.io.require_dir( output_p );
  
  do_save( output_filename, spk_struct );
end

end

function do_save(filename, spk_struct)
save( filename, 'spk_struct' );
end

function [spks, t_series] = align_one_unit( spk_times, event_times, lb, la, ws, ss )

t_series = lb:ss:la;

spks = cell( numel(event_times), numel(t_series) );

for i = 1:numel(event_times)
  et = event_times(i);
  
  for j = 1:numel(t_series)
    min_t = et + t_series(j) - ws/2;
    max_t = et + t_series(j) + ws/2;
  
    ind = spk_times >= min_t & spk_times < max_t;

    %   ensure spike times start from 0 (start of window)
    subset_spikes = spk_times(ind) - min_t;
    
    spks{i, j} = subset_spikes(:);
  end
end

end