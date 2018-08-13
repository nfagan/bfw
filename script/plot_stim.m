
bounds_orig = eg_stim();

%%

conf = bfw.config.load();
save_p = fullfile( conf.PATHS.data_root, 'plots', 'stim', 'behavior', datestr(now, 'mmddyy') );

bounds = bounds_orig';
prune( bounds );

% requirecat( bounds, 'dummy_group' );

% each( bounds, {'unified_filename', 'stim_type'}, @(x) sum(x, 1) );

dat = bounds.data;
dat = sum( dat, 2 );
setdata( bounds, dat );

pl = plotlabeled();
pl.add_legend = false;
pl.error_func = @plotlabeled.sem;

x_is = 'stim_type';
groups_are = 'unified_filename';
panels_are = 'unified_filename';

% collapsecat( bounds, 'unified_filename' );

sessions = bounds( 'unified_filename' );

full_save_p = fullfile( save_p, 'total_looking', 'per_session_fixations' );

for i = 1:numel(sessions)

plt = only( bounds', sessions{i} );
prune( plt );

axs = pl.bar( plt, x_is, groups_are, panels_are );

hold( axs(1), 'on' );

ylims = get( axs(1), 'ylim' );

xlim( [0, 3] );

text( 1, ylims(2) - 50, num2str(numel(find(plt, 'stimulate'))) );
text( 2, ylims(2) - 50, num2str(numel(find(plt, 'sham'))) );

shared_utils.io.require_dir( full_save_p );

fname = strjoin( incat(plt, {'stim_type', 'unified_filename'}), '_' );
fname = strrep( fname, '.', '' );

shared_utils.plot.save_fig( gcf, fullfile(full_save_p, fname), {'epsc', 'png', 'fig'}, true );

end

%%

conf = bfw.config.load();
save_p = fullfile( conf.PATHS.data_root, 'plots', 'stim', 'behavior' ...
  , datestr(now, 'mmddyy'), 'total_looking', 'across_sessions_fixations' );

bounds = copy( bounds_orig );
prune( bounds );

dat = bounds.data;
dat = sum( dat, 2 );
setdata( bounds, dat );

pl = plotlabeled();
pl.add_legend = false;
pl.error_func = @plotlabeled.sem;

x_is = 'stim_type';
groups_are = 'unified_filename';
panels_are = 'day';

sessions = 5:13;
sessions = setdiff( sessions, 6 );
session_names = arrayfun( @(x) ['04242018_position_', num2str(x), '.mat'], sessions, 'un', false );

others = 1:6;
other_sessions = arrayfun( @(x) ['04202018_position_', num2str(x), '.mat'], others, 'un', false );

session_names = [ session_names, other_sessions ];

plt = only( bounds', session_names );
prune( plt );

collapsecat( plt, {'unified_filename'} );

shared_utils.io.require_dir( save_p );

axs = pl.bar( plt, x_is, groups_are, panels_are );

fname = strjoin( incat(plt, {'stim_type', 'unified_filename', 'day'}), '_' );

shared_utils.plot.save_fig( gcf, fullfile(save_p, fname), {'epsc', 'png', 'fig'}, true );

