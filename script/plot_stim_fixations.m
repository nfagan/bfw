
look_ahead = 2;
event_info = bin_look_events_by_stim( look_ahead );

%%
event_info2 = debug__check_m1_sync();
%%
p_inbounds = labeled.from( event_info2.p_inbounds );
p_inbounds_t = event_info2.p_inbounds_t / 1e3;

%%

n_fix = labeled.from( event_info.n_fix );
fix_dur = labeled.from( event_info.fix_dur );
total_dur = labeled.from( event_info.total_dur );
p_lookback = labeled.from( event_info.p_look_back );
p_inbounds = labeled.from( event_info.p_in_bounds );
vel = labeled.from( event_info.vel );

p_inbounds_t = event_info.p_in_bounds_t / 1e3;

%%  stats

to_stats = fix_dur';
prune( only(to_stats, {'04242018', '04252018'}) );
to_rm = bfw.num2cat( 2:6, 'session__' );
to_keep = setdiff( 1:size(to_stats, 1), find(to_stats, ['042418', to_rm]) );
prune( keep(to_stats, to_keep) );

only( to_stats, 'eyes' );

specificity = { 'looks_to', 'day' };

data = getdata( to_stats );
labs = getlabels( to_stats );
[y, I] = keepeach( labs', specificity );

ps = zeros( numel(I), 1 );

for i = 1:numel(I)
  
  ind_stim = intersect( I{i}, find(labs, 'stimulate') );
  ind_sham = intersect( I{i}, find(labs, 'sham') );
  
  ps(i) = ranksum( data(ind_stim), data(ind_sham) );
end

ps = Container.from( labeled(ps, y) );
means = each( to_stats', [specificity, 'stim_type'], @(x) nanmean(x) );

tbl_means = table( Container.from(means), {'stim_type', 'day'} );
tbl_ps = table( ps, {'day'} );

%%

conf = bfw.config.load();
base_save_p = fullfile( conf.PATHS.data_root, 'plots', 'stim', 'behavior', datestr(now, 'mmddyy') );

%%  per session

pl = plotlabeled();
pl.error_func = @plotlabeled.sem;
pl.one_legend = true;

x_is = 'stim_type';
groups_are = 'meas_type';
panels_are = {'unified_filename', 'look_ahead', 'looks_to' };

to_plt = fix_dur';

prune( only(to_plt, {'04242018', '04252018'}) );

is_dur = all( strcmp(to_plt('meas_type'), 'duration') );
is_nfix = all( strcmp(to_plt('meas_type'), 'n_fix') );

sessions = combs( to_plt, 'unified_filename' );

for i = 1:numel(sessions)
  plt = prune( only(to_plt', sessions{i}) );
  
  axs = pl.bar( plt, x_is, groups_are, panels_are );
  
  if ( is_dur )
    ylabel( axs(1), 'Fix duration (ms)' );
  elseif ( is_nfix )
    ylabel( axs(1), 'N fixations' );
  end
  
  fname = strjoin( incat(plt, {'stim_type', 'meas_type', 'unified_filename'}), '_' );
  fname = strrep( fname, '.', '' );
  
  full_save_p = fullfile( base_save_p, 'fix_per_session', strjoin(incat(plt, 'meas_type'), '_') );
  
  shared_utils.io.require_dir( full_save_p );
  shared_utils.plot.save_fig( gcf, fullfile(full_save_p, fname), {'epsc', 'png', 'fig'}, true );  
end


%%  across sessions

pl = plotlabeled();
pl.error_func = @plotlabeled.sem;
pl.one_legend = true;
% pl.shape = [2, 2];

x_is = 'stim_type';
groups_are = { 'meas_type', 'look_ahead' };
panels_are = { 'session', 'day', 'looks_to' };

plt = vel';
setdata( plt, plt.data * 1000 );

prune( only(plt, {'042418', '042518'}) );

to_rm = bfw.num2cat( 2:6, 'session__' );
to_keep = setdiff( 1:size(plt, 1), find(plt, ['042418', to_rm]) );
prune( keep(plt, to_keep) );

collapsecat( plt, 'session' );

is_dur = all( strcmp(plt('meas_type'), 'duration') );
is_nfix = all( strcmp(plt('meas_type'), 'n_fix') );

axs = pl.bar( plt, x_is, groups_are, panels_are );

lims = get( axs(1), 'ylim' );

ylim( axs, [0, lims(2)] );

if ( is_dur )
  ylabel( axs(1), 'Fix duration (ms)' );
elseif ( is_nfix )
  ylabel( axs(1), 'N fixations' );
end

fname = joincat( plt, {'stim_type', 'meas_type', 'day', 'look_ahead'} );
fname = strrep( fname, '.', '' );

full_save_p = fullfile( base_save_p, 'fix_across_sessions', strjoin(incat(plt, 'meas_type'), '_') );

shared_utils.io.require_dir( full_save_p );
shared_utils.plot.save_fig( gcf, fullfile(full_save_p, fname), {'epsc', 'png', 'fig'}, true );  

%%  plot with session number

plt = n_fix';

sessions = incat( plt, 'session' );
session_ns = cellfun( @(x) str2double(x(numel('session__')+1:end)), sessions );
[~, I] = sort( session_ns );

x_is = 'session';
groups_are = { 'stim_type', 'looks_to' };
panels_are = 'day';

pl = plotlabeled();
pl.error_func = @plotlabeled.sem;
pl.one_legend = true;
pl.x_order = sessions(I);

axs = pl.errorbar( plt, x_is, groups_are, panels_are );

%%  plot by fix n

plt = fix_dur';

prune( only(plt, '042518') );

fix_n = incat( plt, 'fix_n' );
fix_ns = cellfun( @(x) str2double(x(numel('fix_n__')+1:end)), fix_n );
[~, I] = sort( fix_ns );

x_is = 'fix_n';
groups_are = { 'stim_type' };
panels_are = 'day';

pl = plotlabeled();
pl.error_func = @plotlabeled.sem;
pl.one_legend = true;
pl.x_order = fix_ns(I);

axs = pl.errorbar( plt, x_is, groups_are, panels_are );

%%  across sessions, p look back

conf = bfw.config.load();

save_p = fullfile( conf.PATHS.data_root, 'plots', 'stim', 'behavior' ...
  , datestr(now, 'mmddyy'), 'probabilities' );

plot_lookback = true;
is_across_sessions = true;

pl = plotlabeled();
pl.error_func = @plotlabeled.nansem;
pl.summary_func = @plotlabeled.nanmean;
pl.one_legend = true;
pl.smooth_func = @(x) smooth(x, 10);

if ( plot_lookback )
  pl.x = event_info.p_look_back_t;
  plt = p_lookback';
  addtl = 'p_look_back';
else
  pl.x = event_info.p_in_bounds_t;
  pl.y_lims = [0, 1];
  pl.add_smoothing = true;
  plt = p_inbounds';
  addtl = 'p_in_bounds';
end

prune( only(plt, '042418') );

sessions = combs( plt, 'session' );
session_ns = bfw.cat2num( sessions, 'session__' );
[~, sorted_ind] = sort( session_ns );

to_rm = bfw.num2cat( 2:6, 'session__' );
to_keep = setdiff( 1:size(plt, 1), find(plt, ['042418', to_rm]) );

prune( keep(plt, to_keep) );

% only( plt, to_keep );
collapsecat( plt, 'session' );

pl.panel_order = sessions(sorted_ind);

groups_are = 'stim_type';
panels_are = {'day', 'session'};

to_clpse = { 'day' };
sesh_type = 'per_session';

if ( is_across_sessions )
  to_clpse{end+1} = 'unified_filename';
  sesh_type = 'across_sessions';
end

collapsecat( plt, to_clpse );

% [I, C] = findall( plt, 'unified_filename' );
[I, C] = findall( plt, 'day' );

full_save_p = fullfile( save_p, addtl, sesh_type );

for i = 1:numel(I)
  subset_plt = prune( keep(plt', I{i}) );
  axs = pl.lines( subset_plt, groups_are, panels_are );
  
  xlim( axs, [-0.5, 3] );
  
  fname = strjoin( incat(subset_plt, {'unified_filename', 'day'}), '_' );
  fname = strrep( fname, '.', '' );
  
  shared_utils.io.require_dir( full_save_p );  
  shared_utils.plot.save_fig( gcf, fullfile(full_save_p, fname), {'epsc', 'png', 'fig'}, true );
end


%%  across sessions, p look back, compare series

conf = bfw.config.load();

save_p = fullfile( conf.PATHS.data_root, 'plots', 'stim', 'behavior' ...
  , datestr(now, 'mmddyy'), 'probabilities' );

plot_lookback = true;
is_across_sessions = true;

pl = ContainerPlotter();
pl.error_function = @(x, y) plotlabeled.nansem(x);
pl.summary_function = @(x, y) plotlabeled.nanmean(x);
pl.one_legend = true;
% pl.smooth_function = @(x) smooth(x, 10);
pl.add_ribbon = true;
pl.compare_series = true;
pl.p_correct_type = 'fdr';
pl.marker_size = 8;

figure(1);

if ( plot_lookback )
  pl.x = event_info.p_look_back_t;
  plt = p_lookback';
  addtl = 'p_look_back';
else
  pl.x = p_inbounds_t;
  pl.y_lim = [0, 1];
  pl.add_smoothing = false;
  plt = p_inbounds';
  addtl = 'p_in_bounds';
end

prune( only(plt, {'042418', 'eyes'}) );

sessions = combs( plt, 'session' );
session_ns = bfw.cat2num( sessions, 'session__' );
[~, sorted_ind] = sort( session_ns );

to_rm = bfw.num2cat( 2:6, 'session__' );
to_keep = setdiff( 1:size(plt, 1), find(plt, ['042418', to_rm]) );
prune( keep(plt, to_keep) );

% only( plt, to_keep );
collapsecat( plt, 'session' );

pl.order_panels_by = sessions(sorted_ind);

groups_are = 'stim_type';
panels_are = {'day', 'session', 'looks_to'};

to_clpse = { 'day' };
sesh_type = 'per_session';

if ( is_across_sessions )
  to_clpse{end+1} = 'unified_filename';
  sesh_type = 'across_sessions';
end

collapsecat( plt, to_clpse );

% [I, C] = findall( plt, 'unified_filename' );
[I, C] = findall( plt, 'day' );

full_save_p = fullfile( save_p, addtl, sesh_type );

for i = 1:numel(I)
  subset_plt = prune( keep(plt', I{i}) );
  axs = pl.plot( Container.from(subset_plt), groups_are, panels_are );
  
  xlim( axs, [-0.5, 3] );
  
  fname = strjoin( incat(subset_plt, {'unified_filename', 'day'}), '_' );
  fname = strrep( fname, '.', '' );
  
  shared_utils.io.require_dir( full_save_p );  
  shared_utils.plot.save_fig( gcf, fullfile(full_save_p, fname), {'epsc', 'png', 'fig'}, true );
end
