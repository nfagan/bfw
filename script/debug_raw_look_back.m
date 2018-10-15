function outs = debug_raw_look_back(varargin)

import shared_utils.io.fload;

defaults = bfw.get_common_make_defaults();
defaults.is_old_events = false;
defaults.look_back = -1;
defaults.look_ahead = 5;
defaults.keep_within_threshold = 0.3;
defaults.samples_subdir = 'aligned_binned_raw_samples';

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
is_old_events = params.is_old_events;

event_subdir = ternary( is_old_events, 'events', 'raw_events' );
samples_subdir = params.samples_subdir;

stim_p =    bfw.gid( 'stim', conf );
meta_p =    bfw.gid( 'meta', conf );
events_p =  bfw.gid( event_subdir, conf );
samples_p = bfw.gid( samples_subdir, conf );

stim_mats = bfw.require_intermediate_mats( params.files, stim_p, params.files_containing );

all_labs = fcat();
all_traces = [];
all_to_keep = logical([]);
all_offsets = [];

look_back = params.look_back;
look_ahead = params.look_ahead;

keep_thresh = params.keep_within_threshold;

for idx = 1:numel(stim_mats)
  shared_utils.general.progress( idx, numel(stim_mats) );
  
  stim_file = shared_utils.io.fload( stim_mats{idx} );

  un_filename = stim_file.unified_filename;
  
  try
    events_file = fload( fullfile(events_p, un_filename) );
    time_file =   fload( fullfile(samples_p, 'time', un_filename) );
%     bounds_file = fload( fullfile(samples_p, 'bounds', un_filename) );
%     fix_file =    fload( fullfile(samples_p, 'arduino_fixations', un_filename) );
    meta_file =   fload( fullfile(meta_p, un_filename) );
  catch err
    bfw.print_fail_warn( un_filename, err.message );
    continue;
  end
  
  if ( is_old_events )
    events_file = bfw.get_reformatted_events( events_file );
  end
  
  event_labs = fcat.from( events_file.labels, events_file.categories );
  event_times = events_file.events(:, events_file.event_key('start_time'));
  event_lengths = events_file.events(:, events_file.event_key('length'));
  t = time_file.t;
  
  look_mask = find( event_labs, {'m1', 'eyes', 'face', 'eyes_nf'} );
  [look_labs, I] = keepeach( event_labs', {'roi', 'looks_by'}, look_mask );
  
  for k = 1:numel(I)
    
    evt_ind = I{k};
    evts = event_times(evt_ind);
    evt_lengths = event_lengths(evt_ind);

    sr = 1 / (1e3/events_file.params.step_size);

    plot_t = look_back:sr:look_ahead;

    stim_times = stim_file.stimulation_times;
    sham_times = stim_file.sham_times;

    all_stim_times = [ stim_times(:); sham_times(:) ];

    all_ib = zeros( numel(all_stim_times), numel(plot_t) );
    to_keep = rowones( numel(all_stim_times), 'logical' );
    offsets = rowzeros( numel(all_stim_times) );

    if ( isempty(all_stim_times) )
      continue;
    end

    for i = 1:numel(all_stim_times)
      current_stim_stim = all_stim_times(i);

      nearest_stim_time_idx = shared_utils.sync.nearest( t, current_stim_stim );
      nearest_stim_time = t(nearest_stim_time_idx); 

      range_times = plot_t + nearest_stim_time;
      evt_idx = find( evts >= range_times(1) & evts <= range_times(end) );

      evts_in_range = evts(evt_idx);
      evt_lengths_in_range = evt_lengths(evt_idx);

      nearest_evt_idx = shared_utils.sync.nearest( range_times, evts_in_range );

      nearest_stim_idx_after_evt = shared_utils.sync.nearest_after( evts_in_range, current_stim_stim );

      if ( nnz(nearest_stim_idx_after_evt) == 0 )
        to_keep(i) = false;
        continue;
      end

      event_offset = current_stim_stim - evts(evt_idx(nearest_stim_idx_after_evt)); 

      to_keep(i) = event_offset < keep_thresh;
      offsets(i) = event_offset;

      for j = 1:numel(nearest_evt_idx)
        evt_start = nearest_evt_idx(j);
        evt_end = evt_start + evt_lengths_in_range(j);

        evt_end = min( evt_end, numel(plot_t) );
        evt_start = max( 1, evt_start );

        all_ib(i, evt_start:evt_end) = 1;
      end
    end

    stim_labs = bfw.make_stim_labels( numel(stim_times), numel(sham_times) );
    join( stim_labs, fcat.from(struct2cell(meta_file)', fieldnames(meta_file)) );
    join( stim_labs, look_labs(k) );

    all_traces = [ all_traces; all_ib ];
    all_to_keep = [ all_to_keep; to_keep ];
    all_offsets = [ all_offsets; offsets ];

    append( all_labs, stim_labs );
  end
end

outs = struct();

outs.t = plot_t;
outs.labels = all_labs;
outs.traces = all_traces;
outs.is_within_threshold = all_to_keep;
outs.event_offsets = all_offsets;

end

% %%
% 
% prune( bfw.get_region_labels(all_labs) );
% 
% % mask = fcat.mask( all_labs );
% % mask = rowmask( all_labs );
% 
% % mask = find( all_to_keep );
% mask = rowmask( all_labs );
% mask = fcat.mask( all_labs, mask, @findnone, {'04202018', 'nonsocial_control'} ...
%   , @find, {'m1', 'eyes'} ...
%   , @find, {'accg'} );
% 
% [y, I] = keepeach( all_labs', {'stim_type', 'unified_filename'}, mask );
% 
% ps = rowmean( all_traces, I );
% 
% pl = plotlabeled.make_common();
% pl.add_errors = false;
% pl.x = plot_t;
% pl.y_lims = [0, 1];
% pl.fig = figure(2);
% % pl.shape = [3, 1];
% 
% axs = pl.lines( ps, y, 'stim_type', {'region', 'roi', 'looks_by'} );
% shared_utils.plot.hold( axs, 'on' );
% shared_utils.plot.add_vertical_lines( axs, [0, -0.15] );