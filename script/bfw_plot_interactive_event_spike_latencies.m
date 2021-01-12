conf = bfw.config.load();

cc_events_file_path_non_eyes = ...
  fullfile( bfw.dataroot(conf), 'public', 'mutual_join_event_idx_and_labels_noneyes.mat' );
cc_events_file_path_eyes = ...
  fullfile( bfw.dataroot(conf), 'public', 'mutual_join_event_idx_and_labels.mat' );

cc_time_file_path = ...
  fullfile( bfw.dataroot(conf), 'public', 'behavior_time_for_interactive_alignment.mat' );

cc_events_file_eyes = load( cc_events_file_path_eyes );
cc_events_file_non_eyes = load( cc_events_file_path_non_eyes );
cc_time_file = load( cc_time_file_path );

cc_events_file_non_eyes.nday = cc_events_file_eyes.nday;

%%

cc_spikes = bfw_gather_spikes( 'spike_subdir', 'cc_spikes' );

%%

[event_inds, event_ts, event_labels] = ...
  bfw_extract_cc_interactive_event_info( cc_events_file_eyes, cc_time_file, 'eyes' );

%%

gathered_labels = gather( event_labels );
save( fullfile(bfw.dataroot(conf), 'public', 'eyes_events.mat'), 'event_ts', 'gathered_labels' );

%%

[session_I, session_C] = findall( event_labels, {'session'} );

psth = cell( numel(session_I), 1 );
psth_labels = cell( size(psth) );
psth_ts = cell( size(psth) );

min_t = -0.5;
max_t = 0.5;
bin_width = 0.05;

for i = 1:numel(session_I)
  shared_utils.general.progress( i, numel(session_I) );
  
  curr_session = session_C{1, i};
  curr_event_ts = event_ts(session_I{i});
  curr_event_labels = event_labels(session_I{i});
  
  units_this_session = find( cc_spikes.labels, curr_session );
  
  unit_psth = [];
  unit_labs = fcat();
  bin_t = [];
  
  for j = 1:numel(units_this_session)
    unit_ind = units_this_session(j);
    curr_unit_labs = cc_spikes.labels(unit_ind);    
    spike_ts = cc_spikes.spike_times{unit_ind};
    
    [tmp_psth, bin_t] = ...
      bfw.trial_psth( spike_ts, curr_event_ts, min_t, max_t, bin_width );
    
    unit_psth = [ unit_psth; tmp_psth ];
    labs = join( curr_event_labels', curr_unit_labs );
    append( unit_labs, labs );
  end
  
  psth{i} = unit_psth;
  psth_labels{i} = unit_labs;
  psth_ts{i} = bin_t;
end

psth = vertcat( psth{:} );
psth_labels = vertcat( fcat, psth_labels{:} );
psth_t = psth_ts{1};

%%

% base_mask = findnone( psth_labels, 'follow' );
base_mask = find( psth_labels, 'join' );

% plot_each = { 'initiated-by', 'followed-by', 'joint-event-type' };
plot_each = { 'joint-event-type' };

[plot_I, plot_C] = findall( psth_labels, plot_each, base_mask );

plot_types = { 'spectra' };
plot_combs = dsp3.numel_combvec( plot_I, plot_types );

for i = 1:size(plot_combs, 2)
  
plot_c = plot_combs(:, i);
comb_index = plot_c(1);

plot_mask = plot_I{comb_index};
plot_labels = plot_C(:, comb_index);

y_lims = [];
plot_type = plot_types{plot_c(2)};
base_subdir = strjoin( plot_labels, '_' );
base_subdir = strrep( base_subdir, '<', '' );
base_subdir = strrep( base_subdir, '>', '' );

target_categories = union( {'joint-event-type', 'initiated-by'}, plot_each );

mask_func = @(l, m) fcat.mask(l, intersect(m, plot_mask) ...
  , @findor, {'solo', 'join'} ...
);

% hist_pcats = { 'region', 'roi' };
% hist_gcats = target_categories;

hist_pcats = target_categories;
hist_gcats = { 'region', 'roi' };

bfw_plot_spike_latencies( psth, psth_labels', psth_t ...
  , 'mask_func', mask_func ...
  , 'config', conf ...
  , 'base_subdir', base_subdir ...
  , 'do_save', true ...
  , 'plot_type', plot_type ...
  , 'y_lims', y_lims ...
  , 'target_categories', target_categories ...
  , 'hist_gcats', hist_gcats ...
  , 'hist_pcats', hist_pcats ...
  , 'anova_each', {} ...
  , 'anova_categories', {'initiated-by', 'region'} ...
);

end
