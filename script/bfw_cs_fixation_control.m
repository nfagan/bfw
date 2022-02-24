conf = bfw.config.load();

events = bfw_gather_events( ...
    'config', conf ...
  , 'require_stim_meta', false ...
  , 'event_subdir', 'remade_032921' ...
);
sorted_events = bfw.sort_events( events );
% sorted_events = shared_utils.io.fload( fullfile(bfw.dataroot(conf) ...
%   , 'analyses/events/sorted_events.mat') );

use_whole_face = true;

if ( use_whole_face )
  [~, transform_ind] = bfw.make_whole_face_roi( sorted_events.labels );
  sorted_events.events = sorted_events.events(transform_ind, :);

  rm_ind = find( sorted_events.labels, {'eyes_nf', 'face'} );
  keep_ind = setdiff( rowmask(sorted_events.labels), rm_ind );

  sorted_events.events(rm_ind, :) = [];
  keep( sorted_events.labels, keep_ind );

  assert_ispair( sorted_events.events, sorted_events.labels );

  sorted_events = bfw.sort_events( sorted_events );
end

cs_events = bfw_gather_cs_events( 'config', conf, 'include_labels', false, 'is_parallel', false );

%%

spike_data = bfw_gather_spikes( ...
  'config', conf ...
  , 'spike_subdir', 'cc_spikes' ...
  , 'is_parallel', true ...
);

bfw.add_monk_labels( spike_data.labels );

%%

% cs_event_name = 'iti';
cs_event_name = 'fixation';
cs_fix_events = cs_events.events(:, strcmp(cs_events.event_key, cs_event_name));
[cs_I, cs_sessions] = findall( cs_events.labels, 'session' );

start_ts = bfw.event_column( sorted_events, 'start_time' );
min_t = 0;
max_t = 0.5;
bin_width = 0.05;

ps = [];
p_labels = fcat();

for i = 1:numel(cs_I)
  shared_utils.general.progress( i, numel(cs_I) );
  
  match_units = find( spike_data.labels, cs_sessions{i} );
  match_gaze_events = find( sorted_events.labels, [cs_sessions(i), {'whole_face'}] );
  
  if ( isempty(match_gaze_events) || isempty(match_units) )
    continue;
  end
  
  subset_fix_events = cs_fix_events(cs_I{i});
  subset_gaze_events = start_ts(match_gaze_events);
  
  for j = 1:numel(match_units)
    spike_ts = spike_data.spike_times{match_units(j)};    
    cs_psth = bfw.trial_psth( spike_ts, subset_fix_events, min_t, max_t, bin_width );
    gaze_psth = bfw.trial_psth( spike_ts, subset_gaze_events, min_t, max_t, bin_width );
    
    cs_psth = nanmean( cs_psth, 2 );
    gaze_psth = nanmean( gaze_psth, 2 );
    
    p = ranksum( cs_psth, gaze_psth );
    ps(end+1, 1) = p;
    
    append( p_labels, spike_data.labels, match_units(j) );
  end
end

%%

count_labels = fcat();

for i = 1:numel(cs_I)
  shared_utils.general.progress( i, numel(cs_I) );
  
  match_units = find( spike_data.labels, cs_sessions{i} );
  match_gaze_events = find( sorted_events.labels, [cs_sessions(i), {'whole_face'}] );
  
  if ( ~isempty(match_gaze_events) && ~isempty(match_units) )
    for j = 1:numel(match_units)
      append( count_labels, spike_data.labels, match_units(j) );
    end
  end
end


%%  venn with hierarchical anova

use_remade = true;
hierarch_anova_sig_cell_labels = shared_utils.io.fload( ...
  fullfile(bfw.dataroot, 'analyses/anova_class/sig_labels/archive/sig_soc_labels_remade.mat') );

existing_units = combs( p_labels, {'unit_uuid', 'region', 'session'} );
keep_hierarch = [];
for i = 1:size(existing_units, 1)
  keep_hierarch = union( keep_hierarch, find(hierarch_anova_sig_cell_labels, existing_units(i, :)) );
end
hierarch_anova_sig_cell_labels = hierarch_anova_sig_cell_labels(keep_hierarch);

addsetcat( p_labels, 'anova-significant', 'anova-significant-false' );
setcat( p_labels, 'anova-significant', 'anova-significant-true', find(ps < 0.05) );

plot_venn_hierarch_anova_with_control_anova( hierarch_anova_sig_cell_labels, p_labels' ...
  , 'lims', [-20, 20] ...
  , 'do_save', true ...
  , 'prefix', sprintf('%s--', cs_event_name) ...
)

%%

do_save = true;

pl = plotlabeled.make_common();
pl.pie_include_percentages = true;
pl.pie_percentage_format = '%s (%d)';

plt_labels = p_labels';
addsetcat( plt_labels, 'sig', 'sig_false' );
setcat( plt_labels, 'sig', 'sig_true', find(ps < 0.05) );
[props, prop_labels] = proportions_of( plt_labels, {'region'}, 'sig' );
cts = counts_of( plt_labels, {'region'}, 'sig' );

% axs = pl.pie( props*1e2, prop_labels, 'sig', 'region' );
axs = pl.pie( cts, prop_labels, 'sig', 'region' );

if ( do_save )
  save_p = fullfile( bfw.dataroot(conf), 'plots', 'cs_fixation_control', dsp3.datedir, 'pie' );
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, prop_labels, 'region', sprintf('%s--', cs_event_name) );
end

%%

function plot_venn_hierarch_anova_with_control_anova(hierarch_labels, control_labels, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.lims = [-13, 13];
params = bfw.parsestruct( defaults, varargin );

%%

unit_cats = {'unit_uuid', 'region', 'session'};

base_mask_ctrl = rowmask( control_labels );
base_mask_h = rowmask( hierarch_labels );

pcats = {'region'};
[control_I, ctrl_C] = findall( control_labels, pcats, base_mask_ctrl );

shp = plotlabeled.get_subplot_shape( numel(control_I) );
axs = gobjects( numel(control_I), 1 );
clf();

for i = 1:numel(control_I)
  ax = subplot( shp(1), shp(2), i );
  axs(i) = ax;
  
  control_sig_mask = find( control_labels, 'anova-significant-true', control_I{i} );
  control_combs = combs( control_labels, unit_cats, control_sig_mask );
  control_cat = categorical( control_combs' );
  
  h_sig_mask = find( hierarch_labels, 'significant', base_mask_h );
  h_sig_mask = find( hierarch_labels, ctrl_C(1, i), h_sig_mask );
  h_sig_combs = combs( hierarch_labels, unit_cats, h_sig_mask );
  h_sig_cat = categorical( h_sig_combs' );
  
  num_h = size( setdiff(h_sig_cat, control_cat, 'rows'), 1 );
  num_ctrl = size( setdiff(control_cat, h_sig_cat, 'rows'), 1 );
  num_shared = size( intersect(h_sig_cat, control_cat, 'rows'), 1 );
  
  num_units = num_h + num_ctrl + num_shared;
  
  p_h = num_shared/(num_h+num_shared)* 1e2;
  p_ctrl = num_shared/(num_ctrl+num_shared)* 1e2;
  p_shared = num_shared/num_units * 1e2;
  
  plt_num_h = num_h + num_shared;
  plt_num_ctrl = num_ctrl + num_shared;
  plt_num_shared = num_shared;
  
  [v, s] = venn( [num_h + num_shared, num_ctrl+num_shared], num_shared );
  
  text( s.Position(1, 1), s.Position(1, 2)+2, sprintf('H-Anova: %d (%0.2f%%)', plt_num_h, p_h) );
  text( s.Position(2, 1), s.Position(2, 2), sprintf('Ctrl: %d (%0.2f%%)', plt_num_ctrl, p_ctrl) );  
  text( s.ZoneCentroid(3, 1), s.ZoneCentroid(3, 2) - 2, sprintf('Shared: %d (%0.2f%%)', plt_num_shared, p_shared) );
  text( s.ZoneCentroid(3, 1), s.ZoneCentroid(3, 2) - 4, sprintf('Total: %d', num_units) );
  
  title( ax, strrep(strjoin(ctrl_C(:, i), ' | '), '_', ' ') );
end

shared_utils.plot.set_xlims( axs, params.lims );
shared_utils.plot.set_ylims( axs, params.lims );

if ( params.do_save )
  shared_utils.plot.fullscreen( gcf() );
  save_p = fullfile( bfw.dataroot(params.config), 'plots', 'cs_fixation_control' ...
    , dsp3.datedir(), params.base_subdir, 'venn' );
  dsp3.req_savefig( gcf, save_p, control_labels, pcats, params.prefix );
end

end

