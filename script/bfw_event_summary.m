function bfw_event_summary(linearized_events, prev_next_outs, roi_areas, mask, varargin)

defaults = struct();
defaults.base_subdir = '';
defaults.base_plot_p = fullfile( bfw.dataroot, 'plots', 'behavior', dsp3.datedir );
defaults.save_figs = true;
defaults.save_stats = true;
defaults.make_figs = true;
defaults.rois = { 'eyes_nf', 'face', 'mouth' };
defaults.base_specificity = 'unified_filename';
defaults.is_previous = true;
defaults.is_stim = false;
defaults.is_roi_area_normalized = false;

params = bfw.parsestruct( defaults, varargin );

%%
start_times = linearized_events.events(:, linearized_events.event_key('start_time'));
stop_times = linearized_events.events(:, linearized_events.event_key('stop_time'));

event_durations = (stop_times - start_times) * 1e3;  % s -> ms
event_labels = linearized_events.labels';

%%

params.base_mask = mask;

handle_n_events( event_labels', roi_areas, params );
handle_event_duration( event_durations, event_labels', roi_areas, params );
handle_initiator_terminator( event_labels', params );
handle_conditional_events( prev_next_outs, params );

end

function areas = match_areas(labs, roi_areas, base_specificity)

find_each = unique( cshorzcat(base_specificity, 'roi', 'looks_by') );
looks_by_ind = find( strcmp(find_each, 'looks_by') );

[I, C] = findall( labs, find_each );

areas = nan( rows(labs), 1 );

for i = 1:numel(I)
  c = C(:, i);
  
  looks_by = c{looks_by_ind};
  
  % Match mutual to m1.
  if ( strcmp(looks_by, 'mutual') )
    c{looks_by_ind} = 'm1';
  end
  
  roi_ind = find( roi_areas.labels, c );
  
  assert( numel(unique(roi_areas.area(roi_ind))) == 1, 'More or fewer than 1 roi matched.' );
  
  areas(I{i}) = roi_areas.area(roi_ind(1));
end

end

function handle_n_events(uselabs, roi_areas, params)

%%  N events

subdir = '';

mask = fcat.mask( uselabs, params.base_mask ...
  , @find, {'no-stimulation', 'free_viewing'} ...
  , @find, {'eyes_nf', 'mouth', 'face'} ...
);

measure_name = 'n_events';

if ( params.is_roi_area_normalized )
  measure_name = sprintf( '%s_density', measure_name );
end

count_each = unique( cshorzcat(params.base_specificity, 'roi', 'looks_by') );
[fix_labels, fix_I] = keepeach( uselabs', count_each, mask );

areas = match_areas( fix_labels, roi_areas, params.base_specificity );

n_fix = cellfun( @numel, fix_I );

if ( params.is_roi_area_normalized )
  n_fix = n_fix ./ areas;
end

pl = plotlabeled.make_common();
pl.x_order = { 'eyes_nf', 'mouth' };
pl.add_points = true;

pcat_sets = {  {}, {'id_m1'}, {'id_m1', 'id_m2'} };

for i = 1:numel(pcat_sets)

  xcats = { 'roi' };
  gcats = { 'looks_by' };
  pcats = pcat_sets{i};
  
  prefix = ternary( isempty(pcats), 'collapsed', strjoin(pcats, '_') );

  if ( params.make_figs )
    axs = pl.bar( n_fix, fix_labels, xcats, gcats, pcats );

    if ( params.save_figs )
      plot_p = fullfile( params.base_plot_p, params.base_subdir, measure_name, subdir );
      plot_cats = cshorzcat( gcats, pcats );

      dsp3.req_savefig( gcf, plot_p, fix_labels, plot_cats, prefix );
    end
  end
end

%%  N events anova within monkey

anova_dat = n_fix;
anova_labs = fix_labels';

factors = { 'roi', 'looks_by' };

anova_nv_pairs = struct( 'remove_nonsignificant_comparisons', false );

event_anova_outs_per_m1 = dsp3.anovan( anova_dat, anova_labs, 'id_m1', factors, anova_nv_pairs );
event_anova_outs = dsp3.anovan( anova_dat, anova_labs, {}, factors, anova_nv_pairs );

if ( params.save_stats )
  plot_p = fullfile( params.base_plot_p, params.base_subdir, measure_name, 'stats' );
  m1_plot_p = fullfile( plot_p, 'per_m1' );
  all_plot_p = fullfile( plot_p, 'all_m1' );
  
  filenames_are = cshorzcat( factors, 'id_m1' );
  
  dsp3.save_anova_outputs( event_anova_outs_per_m1, m1_plot_p, filenames_are );
  dsp3.save_anova_outputs( event_anova_outs, all_plot_p, filenames_are );
end

end

function handle_event_duration(pltdat, event_labels, roi_areas, params)

%  Event duration

subdir = '';

pltlabs = event_labels';

mask = fcat.mask( pltlabs, params.base_mask ...
  , @find, {'no-stimulation', 'free_viewing'} ...
  , @find, {'eyes_nf', 'mouth', 'face'} ...
);

duration_each = unique( cshorzcat(params.base_specificity, 'roi', 'looks_by') );
[pltlabs, dur_I] = keepeach( pltlabs', duration_each, mask );

pltdat = bfw.row_nanmean( pltdat, dur_I );

measure_name = 'event_duration';

if ( params.is_roi_area_normalized )
  areas = match_areas( pltlabs, roi_areas, params.base_specificity );
  
  pltdat = pltdat ./ areas;
  
  measure_name = sprintf( '%s_density', measure_name );
end

pl = plotlabeled.make_common();
pl.fig = figure(2);
pl.group_order = { 'm1', 'm2' };
pl.x_order = { 'eyes_nf', 'mouth' };
pl.add_points = true;

pcat_sets = { {'id_m1'}, {'id_m1', 'id_m2'}, {} };

for i = 1:numel(pcat_sets)

  xcats = { 'roi' };
  gcats = { 'looks_by' };
  pcats = pcat_sets{i};
  
  prefix = ternary( isempty(pcats), 'collapsed', strjoin(pcats, '_') );

  if ( params.make_figs )
    axs = pl.bar( pltdat, pltlabs, xcats, gcats, pcats );

    if ( params.save_figs )
      plot_p = fullfile( params.base_plot_p, params.base_subdir, measure_name, subdir );
      plot_cats = cshorzcat( gcats, pcats );

      dsp3.req_savefig( gcf, plot_p, prune(pltlabs), plot_cats, prefix );
    end
  end
end

%%  Anova duration

anova_dat = pltdat;
anova_labs = pltlabs';

factors = { 'roi', 'looks_by' };

anova_nv_pairs = struct( 'remove_nonsignificant_comparisons', false );

duration_anova_outs_per_m1 = dsp3.anovan( anova_dat, anova_labs, 'id_m1', factors, anova_nv_pairs );
duration_anova_outs = dsp3.anovan( anova_dat, anova_labs, {}, factors, anova_nv_pairs );

if ( params.save_stats )
  plot_p = fullfile( params.base_plot_p, params.base_subdir, measure_name, 'stats' );
  m1_plot_p = fullfile( plot_p, 'per_m1' );
  all_plot_p = fullfile( plot_p, 'all_m1' );
  
  filenames_are = cshorzcat( factors, 'id_m1' );
  
  dsp3.save_anova_outputs( duration_anova_outs_per_m1, m1_plot_p, filenames_are );
  dsp3.save_anova_outputs( duration_anova_outs, all_plot_p, filenames_are );
end

end

function handle_initiator_terminator(event_labels, params)

%  Mutual initiator / terminator

prefix = '';
subdir = '';

is_initiators = [ true, false ];
panel_spec = { {}, {'id_m1'}, {'id_m1', 'id_m2'} };

all_C = dsp3.numel_combvec( is_initiators, panel_spec );

for i = 1:size(all_C, 2)

  uselabs = event_labels';
  is_initiator = is_initiators(all_C(1, i));
  additional_panel_spec = panel_spec{all_C(2, i)};

  mask = fcat.mask( uselabs, params.base_mask ...
    , @find, {'mutual'} ...
    , @find, {'eyes_nf', 'mouth', 'face'} ...
    , @find, {'no-stimulation', 'free_viewing'} ...
  );

  full_prefix = sprintf( '%s%s', char(strjoin(additional_panel_spec, '_')), prefix );

  props_each = unique( cshorzcat(params.base_specificity, 'roi', 'looks_by') );

  [prop_initiator, init_labels] = proportions_of( uselabs', props_each, 'initiator', mask );
  [prop_terminator, term_labels] = proportions_of( uselabs', props_each, 'terminator', mask );

  if ( is_initiator )
    pltlabels = init_labels';
    pltdat = prop_initiator;

    props_of_category = 'initiator';
  else
    pltlabels = term_labels';
    pltdat = prop_terminator;

    props_of_category = 'terminator';
  end

  pl = plotlabeled.make_common();
  pl.x_order = { 'eyes_nf', 'mouth' };
  pl.y_lims = [0, 1];
  pl.add_points = true;

  xcats = { 'roi' };
  gcats = { props_of_category };
  pcats = {};
  
  if ( ~isempty(additional_panel_spec) )
    pcats = cshorzcat( pcats, additional_panel_spec );
  end
  
  if ( params.make_figs )
    axs = pl.bar( pltdat, pltlabels, xcats, gcats, pcats );

    if ( params.save_figs )
      plot_p = fullfile( params.base_plot_p, params.base_subdir ...
        , 'event_initiator_terminator', subdir );
      plot_cats = cshorzcat( gcats, pcats );

      dsp3.req_savefig( gcf, plot_p, pltlabels, plot_cats, full_prefix );
    end
  end
end

%%  Anova terminator

for i = 1:2
  uselabs = event_labels';

  mask = fcat.mask( uselabs, params.base_mask ...
    , @find, {'mutual'} ...
    , @find, {'eyes_nf', 'mouth', 'face'} ...
    , @find, {'no-stimulation', 'free_viewing'} ...
  );

  props_each = unique( cshorzcat(params.base_specificity, 'roi', 'looks_by') );
  
  if ( i == 1 )
    props_of_category = 'initiator';
  else
    props_of_category = 'terminator';
  end
  
  [prop_init_term, labs] = proportions_of( uselabs', props_each, props_of_category, mask );

  factors = { 'roi', props_of_category };
  
  anova_nv_pairs = struct( 'remove_nonsignificant_comparisons', false );

  term_init_anova_outs_per_m1 = dsp3.anovan( prop_init_term, labs, 'id_m1', factors, anova_nv_pairs );

  term_init_anova_outs = dsp3.anovan( prop_init_term, labs, {}, factors ...
    , 'dimension', 1:2 ...
    , anova_nv_pairs ...
  );

  specific_mask = fcat.mask( labs ...
    , @find, {'m1_lynch', 'm2_cron'} ...
    , @findnone, 'simultaneous_start' ...
  );
  
  lynch_cron_anova = dsp3.anovan( prop_init_term, labs, {}, factors, anova_nv_pairs ...
    , 'mask', specific_mask );

  if ( params.save_stats )
    plot_p = fullfile( params.base_plot_p, params.base_subdir, 'event_initiator_terminator', 'stats' );
    m1_plot_p = fullfile( plot_p, 'per_m1' );
    all_plot_p = fullfile( plot_p, 'all_m1' );
    lynch_cron_p = fullfile( plot_p, 'm1_lynch_m2_cron' );

    filenames_are = cshorzcat( factors, 'id_m1' );

    dsp3.save_anova_outputs( term_init_anova_outs_per_m1, m1_plot_p, filenames_are );
    dsp3.save_anova_outputs( term_init_anova_outs, all_plot_p, filenames_are );
    dsp3.save_anova_outputs( lynch_cron_anova, lynch_cron_p, filenames_are );
  end
end

end

function handle_conditional_events(prev_next_outs, params)

%% Cound proportions of each event type

is_previous = params.is_previous;
is_stim = params.is_stim;

if ( is_previous )
  labs = prev_next_outs.prev_labels';
  event_intervals = prev_next_outs.prev_intervals;
  missing_lab = '<previous_roi>';
  proportion_cats = { 'previous_roi', 'previous_looks_by' };
  
else
  labs = prev_next_outs.next_labels';
  event_intervals = prev_next_outs.next_intervals;
  missing_lab = '<next_roi>';
  proportion_cats = { 'next_roi', 'next_looks_by' };
end

min_iei = -Inf;
max_iei = 5;
use_interval_thresh = true;

if ( use_interval_thresh )
  mask = find( event_intervals > min_iei & event_intervals < max_iei );
else
  mask = rowmask( labs );
end

mask = fcat.mask( labs, mask ...
  , @find, params.rois ...
  , @findnone, {'mutual', 'previous_mutual', 'next_mutual'} ...
  , @find, 'free_viewing' ...
  , @findnone, missing_lab ...
  , @find, 'm1' ...
);

if ( is_stim )
  mask = find( labs, 'm1_exclusive_event', mask );
else
  mask = find( labs, 'no-stimulation', mask );
end

props_each = unique( cshorzcat(params.base_specificity, 'roi', 'looks_by') );

if ( is_stim )
  props_each{end+1} = 'protocol_name';
end

props_of = proportion_cats;

[props, pltlabs] = proportions_of( labs, props_each, props_of, mask );

%%  plot

subdir = ternary( is_stim, 'stim', 'no-stim' );

pcat_sets = { {'id_m1'}, {'id_m1', 'id_m2'}, {} };

for i = 1:numel(pcat_sets)

  pl = plotlabeled.make_common();
  % pl.y_lims = [0, 0.5];
  % pl.x_tick_rotation = 0;
  pl.fig = figure(2);
  pl.add_points = true;

  fcats = { 'id_m1' };
  xcats = proportion_cats{2};
  gcats = { proportion_cats{1}, 'protocol_name' };
  pcats = unique( cshorzcat(pcat_sets{i}, 'looks_by', 'roi') );
  
  prefix = ternary( isempty(pcat_sets{i}), 'collapsed', strjoin(pcat_sets{i}, '_') );

  if ( params.make_figs )
    [figs, axs, I] = pl.figures( @bar, props, pltlabs, fcats, xcats, gcats, pcats );

    if ( params.save_figs )
      for i = 1:numel(figs)
        plot_p = fullfile( params.base_plot_p, params.base_subdir, 'conditional_events', subdir );
        plot_cats = cshorzcat( gcats, pcats );

        shared_utils.plot.fullscreen( figs(i) );

        dsp3.req_savefig( figs(i), plot_p, prune(pltlabs(I{i})), plot_cats, prefix );
      end
    end
  end
end

%%  Anova conditional

anova_dat = props;
anova_labs = pltlabs';

factors = proportion_cats;

anova_nv_pairs = struct( 'remove_nonsignificant_comparisons', false );

conditional_anova_outs_per_m1 = dsp3.anovan( anova_dat, anova_labs ...
  , {'id_m1', 'roi'}, factors, anova_nv_pairs );
conditional_anova_outs = dsp3.anovan( anova_dat, anova_labs ...
  , {'roi'}, factors, anova_nv_pairs );
conditional_anova_outs_with_roi = dsp3.anovan( anova_dat, anova_labs ...
  , {}, csunion(factors, 'roi'), anova_nv_pairs );

if ( params.save_stats )
  plot_p = fullfile( params.base_plot_p, params.base_subdir, 'conditional_events', 'stats' );
  plot_p = fullfile( plot_p, ternary(is_stim, 'stim', 'no-stim') );
  
  m1_plot_p = fullfile( plot_p, 'per_m1' );
  all_plot_p = fullfile( plot_p, 'all_m1' );
  roi_plot_p = fullfile( plot_p, 'all_m1_with_factor_roi' );
  
  filenames_are = cshorzcat( factors, {'id_m1', 'roi'} );
  
  dsp3.save_anova_outputs( conditional_anova_outs_per_m1, m1_plot_p, filenames_are );
  dsp3.save_anova_outputs( conditional_anova_outs, all_plot_p, filenames_are );
  dsp3.save_anova_outputs( conditional_anova_outs_with_roi, roi_plot_p, filenames_are );
end

%%  heat map

[heat_map_I, heat_map_C] = findall( pltlabs, {'looks_by', 'roi'}, findnot(pltlabs, 'face') );

hs = gobjects( numel(heat_map_I), 1 );

for i = 1:numel(heat_map_I)
  f = figure(i);
  clf( f );
  
  row_spec = { 'looks_by', proportion_cats{1} };
  col_spec = proportion_cats{2};

  [t, rc] = tabular( pltlabs, row_spec, col_spec, heat_map_I{i} );

  to_plt = cellfun( @(x) nanmean(props(x)), t );
  x_labs = fcat.strjoin( cellstr(rc{2})', ' | ' );
  y_labs = fcat.strjoin( cellstr(rc{1})', ' | ' );

  if ( params.make_figs )
    hs(i) = heatmap( x_labs, y_labs, to_plt, 'parent', f );
  
    title( strjoin(heat_map_C(:, i), ' | ') );  
  end
end

if ( params.make_figs )
  lims = { hs.ColorLimits };
  min_lim = min( cellfun(@min, lims) );
  max_lim = max( cellfun(@max, lims) );

  arrayfun( @(x) set(x, 'colorlimits', [min_lim, max_lim]), hs );
end

end


