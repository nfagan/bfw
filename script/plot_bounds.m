conf = bfw.config.load();

p = bfw.get_intermediate_directory( 'bounds' );

bound_mats = shared_utils.io.find( p, '.mat' );

fs = 1e3;

evt_length = 1;
bin_size = 10 * fs;

n_events_across_sessions = Container();
n_events_within_session = Container();
total_n_samples = Container();

date_dir = datestr( now, 'mmddyy' );
do_save = true;
save_p = fullfile( conf.PATHS.data_root, 'plots', 'looking_behavior', date_dir );

if ( do_save ), shared_utils.io.require_dir( save_p ); end

for i = 1:numel(bound_mats)
  
  bounds = shared_utils.io.fload( bound_mats{i} );
  
  m1 = bounds.m1.bounds;
  m2 = bounds.m2.bounds;
  
  meta = shared_utils.io.fload( fullfile(bfw.get_intermediate_directory('unified') ...
    , bounds.m1.unified_filename) );
  
  m1t = bounds.m1.time;
  m2t = bounds.m2.time;
  
  roi_names = m1.keys();
  
  for j = 1:numel(roi_names)
    
    roi_name = roi_names{j};
    
    m1_bounds = m1(roi_name);
    m2_bounds = m2(roi_name);
    mutual_bounds = m1_bounds & m2_bounds;

    m1_evts = shared_utils.logical.find_starts( m1_bounds, evt_length );
    m2_evts = shared_utils.logical.find_starts( m2_bounds, evt_length );

    mutual = shared_utils.logical.find_starts( mutual_bounds, evt_length );

    session = meta.m1.mat_directory_name;
    run_n = sprintf( 'run_n__%d', meta.m1.mat_index );

    evts = { m1_evts; m2_evts; mutual };

    cont = Container( evts, 'session', session, 'run_n', run_n );
    cont = cont.require_fields( {'m_alias', 'roi'} );
    cont( 'm_alias' ) = { 'm1', 'm2', 'mutual' };
    cont( 'roi' ) = roi_name;
    
    n_events_across_sessions = n_events_across_sessions.append( cont );
    
    p_m1 = sum( m1_bounds ) / numel( m1_bounds );
    p_m2 = sum( m2_bounds ) / numel( m2_bounds );
    p_mutual = sum( mutual_bounds ) / numel( mutual_bounds );
    cont2 = set_data( cont, [p_m1; p_m2; p_mutual] );
    
    total_n_samples = total_n_samples.append( cont2 );
    
    discard_final_bin = true;

    m1_binned = shared_utils.vector.bin( m1_bounds, bin_size, discard_final_bin );
    m1_binned = cellfun( @sum, m1_binned );
    m2_binned = shared_utils.vector.bin( m2_bounds, bin_size, discard_final_bin );
    m2_binned = cellfun( @sum, m2_binned );    
    mutual_binned = shared_utils.vector.bin( mutual_bounds, bin_size, discard_final_bin );
    mutual_binned = cellfun( @sum, mutual_binned );
    
    cont = cont.set_data( [m1_binned; m2_binned; mutual_binned] );
    
    n_events_within_session = n_events_within_session.append( cont );
  end
end

binned_time = shared_utils.vector.bin( m1t, bin_size, discard_final_bin );
binned_time = cellfun( @(x) x(1), binned_time );

%%

numbers = n_events_across_sessions.set_data( cellfun(@numel, n_events_across_sessions.data) );

%%

pl = ContainerPlotter();

% plt = numbers({'face'});
plt = numbers;

nums = plt( 'run_n' );
[~, I] = sort( cellfun(@(x) str2double(x(numel('run_n__')+1:end)), nums) );
nums = nums(I);

pl.order_by = nums;

x_is = 'run_n';
lines_are = { 'm_alias' };
panels_are = { 'session', 'roi' };

figure(1); clf();

plt.plot_by( pl, x_is, lines_are, panels_are );

filenames_are = unique( [lines_are, panels_are] );
filename = sprintf( 'across_runs_looks__%s', strjoin(plt.flat_uniques(filenames_are), '_') );

saveas( gcf(), fullfile(save_p, [filename, '.eps']), 'epsc' );
saveas( gcf(), fullfile(save_p, [filename, '.fig']), 'fig' );
saveas( gcf(), fullfile(save_p, [filename, '.png']), 'png' );

%%  events within session

pl = ContainerPlotter();

pl.x = binned_time;

pl.add_ribbon = true;
pl.x_label = 'Time (s) from sessions start';
pl.y_label = sprintf( '%% of time spent looking per %d (s) bins', bin_size/fs );

plt = n_events_within_session;
% plt = plt({'face'});

plt.data = plt.data / fs;
plt.data = plt.data / 10 * 100;

lines_are = { 'm_alias' };
panels_are = { 'session', 'roi' };

figure(1); clf();

plt.plot( pl, lines_are, panels_are );

filenames_are = unique( [lines_are, panels_are] );
filename = sprintf( 'within_run_looks__%s', strjoin(plt.flat_uniques(filenames_are), '_') );

saveas( gcf(), fullfile(save_p, [filename, '.eps']), 'epsc' );
saveas( gcf(), fullfile(save_p, [filename, '.fig']), 'fig' );
saveas( gcf(), fullfile(save_p, [filename, '.png']), 'png' );

%%   percent of time per session

pl = ContainerPlotter();

x_is = 'm_alias';
groups_are = { 'roi' };
panels_are = { 'session' };

plt = total_n_samples;
plt.data = plt.data * 100;

pl.summary_function = @nanmean;
pl.error_function = @ContainerPlotter.nansem;
pl.y_label = '% of samples in bounds in roi';
pl.y_lim = [0, 10];

figure(1); clf(); colormap( 'default' );

pl.bar( plt, x_is, groups_are, panels_are );

filenames_are = unique( [groups_are, panels_are, x_is] );
filename = sprintf( 'total_percent_looking__%s', strjoin(plt.flat_uniques(filenames_are), '_') );

saveas( gcf(), fullfile(save_p, [filename, '.eps']), 'epsc' );
saveas( gcf(), fullfile(save_p, [filename, '.fig']), 'fig' );
saveas( gcf(), fullfile(save_p, [filename, '.png']), 'png' );


