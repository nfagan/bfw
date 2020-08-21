function bfw_plot_event_summary(events, labels, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.mask_func = @bfw.default_mask_func;
defaults.per_m1_m2 = false;
defaults.per_m1_m2_pair = false;
defaults.per_exlusive_monk_id = false;
defaults.base_specificity = {'unified_filename', 'roi'};
defaults.back_of = { 'looks_by', 'roi' };
defaults.x_order = {};
defaults.normalized_ratio = false;
params = bfw.parsestruct( defaults, varargin );

base_mask = params.mask_func( labels, rowmask(labels) );

% ratio_measures( events, labels, base_mask, params );
% n_back_prop( labels, base_mask, params );
basic_gaze_behavior( events, labels, base_mask, params );

end

function n_back_prop(labels, mask, params)

base_spec = union( base_specificity(params), {'event_type'} );
base_spec = modify_specificity( base_spec, params );

prev_of = cellfun( @(x) sprintf('prev_%s', x), params.back_of, 'un', 0 );
next_of = cellfun( @(x) sprintf('next_%s', x), params.back_of, 'un', 0 );

[prev_props, prev_labs] = proportions_of( labels', base_spec, prev_of, mask );
[next_props, next_labs] = proportions_of( labels', base_spec, next_of, mask );

props = [ prev_props; next_props ];
addsetcat( prev_labs, 'back_type', 'previous' );
addsetcat( next_labs, 'back_type', 'next' );
labs = [ prev_labs'; next_labs ];

pl = plotlabeled.make_common();
pl.y_lims = [0, 1];

fcats = { 'back_type' };
xcats = { 'roi' };
pcats = { 'looks_by' };

% fig_mask = find( labs, 'previous' );
fig_mask = rowmask( labs );

fig_I = findall_or_one( labs, fcats, fig_mask );
for i = 1:numel(fig_I)
  fig_ind = fig_I{i};
  
  if ( strcmp(combs(labs, 'back_type', fig_ind), 'previous') )
    gcats = prev_of;
    n_back_cat = 'n_back_prev';
  else
    gcats = next_of;
    n_back_cat = 'n_back_next';
  end
  
  plt = props(fig_ind);
  plt_labs = prune( labs(fig_ind) );

  axs = pl.bar( plt, plt_labs, xcats, gcats, pcats );
  
  if ( params.do_save )
    shared_utils.plot.fullscreen( gcf );
    save_p = bfw.behav_summary_data_path( 'behavior', 'prop_n_back', params );
    dsp3.req_savefig( gcf, save_p, plt_labs, [fcats, pcats, gcats], params.prefix );
  end
  
  plot_info = struct();
  plot_info.data_type = 'prop_n_back';
  plot_info.subdir = plot_info.data_type;
  plot_info.each = [fcats, pcats];
  plot_info.fcats = {};
  plot_info.pcats = {};
  plot_info.gcats = {};
  plot_info.xcats = {n_back_cat, 'roi'};
  
  tmp_labs = plt_labs';
  to_combine = cellstr( tmp_labs, gcats );
  combined = fcat.strjoin( to_combine', '_' )';
  rmcat( tmp_labs, gcats );
  addsetcat( tmp_labs, n_back_cat, combined );
  
  run_anova_stats( plt, tmp_labs, rowmask(tmp_labs), plot_info, params );
end

end

function pairs = ratio_pairs()

pairs = { ...
  {'whole_face', 'right_nonsocial_object'} ...
  , {'eyes_nf', 'face'} ...
  , {'eyes_nf', 'right_nonsocial_object_eyes_nf_matched'} ...
};

end

function f = make_ratio_field(fieldname)

f = sprintf( 'ratio_%s', fieldname );

end

function ratio_measures(events, labels, mask, params)

base_spec = union( base_specificity(params), {'event_type'} );
base_spec = modify_specificity( base_spec, params );

bhv_info = basic_behavior_summary( events, labels, mask, base_spec );
subdir = 'basic_behavior';

pairs = ratio_pairs();
pair_spec = setdiff( base_spec, 'roi' );
each_I = findall( bhv_info.labels, pair_spec );

to_ratio_fields = setdiff( fieldnames(bhv_info), 'labels' );
ratio_labels = fcat();

for i = 1:numel(to_ratio_fields)
  ratio_field = make_ratio_field( to_ratio_fields{i} );
  bhv_info.(ratio_field) = [];
end

for i = 1:numel(each_I)
  for j = 1:numel(pairs)
    ind_a = find( bhv_info.labels, pairs{j}{1}, each_I{i} );
    ind_b = find( bhv_info.labels, pairs{j}{2}, each_I{i} );
    
    for k = 1:numel(to_ratio_fields)
      ratio_field = make_ratio_field( to_ratio_fields{k} );
      vs = bhv_info.(to_ratio_fields{k});
      
      ma = mean( vs(ind_a) );
      mb = mean( vs(ind_b) );

      if ( params.normalized_ratio )
        ratio = (ma - mb) / (ma + mb);
      else
        ratio = ma / mb;
      end

      bhv_info.(ratio_field)(end+1, 1) = ratio;
    end
    
    roi_label = sprintf( '%s/%s', pairs{j}{:} );
    append1( ratio_labels, bhv_info.labels, each_I{i} );
    setcat( ratio_labels, 'roi', roi_label, rows(ratio_labels) );
  end
end
  
plot_info = struct();
plot_info.fcats = intersect( {'m1_m2', 'exclusive_monk_id'}, base_spec );
plot_info.pcats = {};
plot_info.gcats = intersect( {'event_type', 'looks_by'}, base_spec );
plot_info.xcats = { 'roi' };

plot_ratio_fields = {'ratio_counts', 'ratio_duration', 'ratio_total_duration'};
for i = 1:numel(plot_ratio_fields)

  plot_info.data_type = plot_ratio_fields{i};
  plot_info.subdir = fullfile( subdir, plot_info.data_type );
  plot_info.normalized_ratio = params.normalized_ratio;

  dat = bhv_info.(plot_ratio_fields{i});
  plt_mask = find( isfinite(dat) );

  args = {dat, ratio_labels, plt_mask, plot_info, params};

  plot_bar( args{:} );
  plot_violin( args{:} );
end

end

function basic_gaze_behavior(events, labels, mask, params)

base_spec = union( base_specificity(params), {'event_type'} );
base_spec = modify_specificity( base_spec, params );
init_mask = find( labels, 'mutual', mask );

bhv_info = basic_behavior_summary( events, labels, mask, base_spec );
[init_props, init_labels] = proportions_of( labels', base_spec, 'initiator', init_mask );
[term_props, term_labels] = proportions_of( labels', base_spec, 'terminator', init_mask );

subdir = 'basic_behavior';

plot_info.fcats = intersect( {'m1_m2', 'exclusive_monk_id'}, base_spec );
plot_info.pcats = {};
plot_info.gcats = intersect( {'event_type', 'looks_by'}, base_spec );
plot_info.xcats = { 'roi' };

% nfix
plot_info.data_type = 'N-fix';
plot_info.subdir = fullfile( subdir, plot_info.data_type );

args = {bhv_info.counts, bhv_info.labels, rowmask(bhv_info.labels), plot_info, params};

plot_boxplot( args{:} );
plot_bar( args{:} );
plot_violin( args{:} );

run_anova_stats( bhv_info.counts, bhv_info.labels, rowmask(bhv_info.labels), plot_info, params );

% prop initiated
init_plot_info = plot_info;
init_plot_info.data_type = 'Initiator-proportions';
init_plot_info.subdir = fullfile( subdir, init_plot_info.data_type );
init_plot_info.gcats = union( plot_info.gcats, {'initiator'} );

args = {init_props, init_labels, rowmask(init_labels), init_plot_info, params};
plot_boxplot( args{:} );
plot_bar( args{:} );
plot_violin( args{:} );

run_anova_stats( init_props, init_labels, rowmask(init_labels), init_plot_info, params );

% prop terminated
term_plot_info = init_plot_info;
term_plot_info.data_type = 'Terminator-proportions';
term_plot_info.subdir = fullfile( subdir, term_plot_info.data_type );
term_plot_info.gcats = union( plot_info.gcats, {'terminator'} );

args = {term_props, term_labels, rowmask(term_labels), term_plot_info, params};
plot_boxplot( args{:} );
plot_bar( args{:} );
plot_violin( args{:} );

run_anova_stats( term_props, term_labels, rowmask(term_labels), term_plot_info, params );

% duration
plot_info.data_type = 'Duration';
plot_info.subdir = fullfile( subdir, plot_info.data_type );

args = {bhv_info.duration, bhv_info.labels, rowmask(bhv_info.labels), plot_info, params};
plot_boxplot( args{:} );
plot_bar( args{:} );
plot_violin( args{:} );

run_anova_stats( bhv_info.duration, bhv_info.labels, rowmask(bhv_info.labels), plot_info, params );

% total-duration
plot_info.data_type = 'Total-duration';
plot_info.subdir = fullfile( subdir, plot_info.data_type );

args = {bhv_info.total_duration, bhv_info.labels, rowmask(bhv_info.labels), plot_info, params};
plot_boxplot( args{:} );
plot_bar( args{:} );
plot_violin( args{:} );

run_anova_stats( bhv_info.total_duration, bhv_info.labels, rowmask(bhv_info.labels), plot_info, params );

end

function plot_boxplot(data, labels, mask, plot_info, params)

plot_func = @boxplot;
plot_two( plot_func, data, labels, mask, plot_info, params );

end

function plot_violin(data, labels, mask, plot_info, params)

plot_func = @violinalt;
plot_two( plot_func, data, labels, mask, plot_info, params );

end

function plot_two(plot_func, data, labels, mask, plot_info, params)

fcats = plot_info.fcats;
pcats = plot_info.pcats;
gcats = plot_info.gcats;
xcats = plot_info.xcats;

pcats = union( pcats, fcats );

fig_I = findall_or_one( labels, fcats, mask );
figs = cell( size(fig_I) );
all_axs = cell( size(fig_I) );

pcats = csunion( pcats, xcats );

for i = 1:numel(fig_I)
  figs{i} = figure( i );
  dat = data(fig_I{i});
  labs = prune( labels(fig_I{i}) );
  
  pl = plotlabeled.make_common();
  pl.x_order = params.x_order;
  
  pl.fig = figs{i};
  axs = plot_func( pl, dat, labs, gcats, pcats );  
  ylabel( axs(1), plot_info.data_type );
  all_axs{i} = axs;
end

all_axs = vertcat( all_axs{:} );
shared_utils.plot.match_ylims( all_axs );

if ( params.normalized_ratio && ...
     shared_utils.struct.field_or(plot_info, 'normalized_ratio', false) )
  shared_utils.plot.set_ylims( all_axs, [-1, 1] );
end

for i = 1:numel(figs)
  labs = prune( labels(fig_I{i}) );
  
  if ( params.do_save )
    shared_utils.plot.fullscreen( figs{i} );
    use_subdir = fullfile( plot_info.subdir, func2str(plot_func) );
    save_p = bfw.behav_summary_data_path( 'behavior', use_subdir, params );
    dsp3.req_savefig( figs{i}, save_p, labs, [fcats, pcats, gcats], params.prefix );
  end
end

end

function plot_bar(data, labels, mask, plot_info, params)

fcats = plot_info.fcats;
pcats = plot_info.pcats;
gcats = plot_info.gcats;
xcats = plot_info.xcats;

pcats = union( pcats, fcats );

fig_I = findall_or_one( labels, fcats, mask );
figs = cell( size(fig_I) );
all_axs = cell( size(fig_I) );

for i = 1:numel(fig_I)
  figs{i} = figure( i );
  dat = data(fig_I{i});
  labs = prune( labels(fig_I{i}) );
  
  pl = plotlabeled.make_common();
  pl.x_order = params.x_order;
  
  pl.fig = figs{i};
  axs = pl.bar( dat, labs, xcats, gcats, pcats );  
  ylabel( axs(1), plot_info.data_type );
  all_axs{i} = axs;
end

all_axs = vertcat( all_axs{:} );
shared_utils.plot.match_ylims( all_axs );

for i = 1:numel(figs)
  labs = prune( labels(fig_I{i}) );
  
  if ( params.do_save )
    shared_utils.plot.fullscreen( figs{i} );
    use_subdir = fullfile( plot_info.subdir, 'bars' );
    save_p = bfw.behav_summary_data_path( 'behavior', use_subdir, params );
    dsp3.req_savefig( figs{i}, save_p, labs, [fcats, pcats, gcats], params.prefix );
  end
end

end

function run_anova_stats(data, labels, mask, plot_info, params)

total_spec = unique( [plot_info.xcats, plot_info.gcats, plot_info.pcats, plot_info.fcats] );
total_spec(isuncat(labels, total_spec, mask)) = [];

if ( isfield(plot_info, 'each') )
  each = plot_info.each;
else
  each = {};
end

total_spec = setdiff( total_spec, each );
anova_outs = anova_stats( data, labels, mask, each, total_spec );

if ( params.do_save )
  stat_subdir = fullfile( plot_info.subdir, 'stats' );
  save_p = bfw.behav_summary_data_path( 'behavior', stat_subdir, params );
  dsp3.save_anova_outputs( anova_outs, save_p, union(total_spec, each) );
end

end

function out = anova_stats(data, labels, mask, each, factors)

out = dsp3.anovan( data, labels, each, factors ...
  , 'mask', mask ...
  , 'remove_nonsignificant_comparisons', false ...
);

end

function out = basic_behavior_summary(events, labels, mask, spec)

duration = bfw.event_column( events, 'duration' );

[mean_labs, each_I] = keepeach( labels', spec, mask );
mean_dur = bfw.row_nanmean( duration, each_I );
total_dur = rowop( duration, each_I, @nansum );
mean_counts = cellfun( @numel, each_I );

out = struct();
out.labels = mean_labs;
out.duration = mean_dur;
out.total_duration = total_dur;
out.counts = mean_counts;

assert_ispair( mean_dur, mean_labs );
assert_ispair( mean_counts, mean_labs );

end

function base_spec = base_specificity(params)
base_spec = params.base_specificity;
end

function spec = modify_specificity(spec, params)
if ( params.per_m1_m2 )
  spec = union( spec, {'looks_by'} );
  spec = setdiff( spec, {'event_type'} );
end
if ( params.per_m1_m2_pair )
  spec = union( spec, {'m1_m2'} );
end
if ( params.per_exlusive_monk_id )
  spec = union( spec, {'exclusive_monk_id'} );
  spec = setdiff( spec, {'event_type'} );
end
end