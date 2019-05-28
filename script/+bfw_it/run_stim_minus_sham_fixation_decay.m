function run_stim_minus_sham_fixation_decay(look_outs, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.plot_err = false;
defaults.seed = 1;

params = bfw.parsestruct( defaults, varargin );

labs = look_outs.labels';
bounds = look_outs.bounds;
t = look_outs.t;

handle_labels( labs );
mask = get_base_mask( labs );

per_freq( t, bounds, labs, mask, params );
per_freq_and_image( t, bounds, labs, mask, params );
per_freq_and_image_direction( t, bounds, labs, mask, params );

end

function per_freq_and_image(t, bounds, labs, mask, params)

cond_spec = { 'stim_frequency', 'image_monkey' };
per_condition( t, bounds, labs, cond_spec, 'stim_frequency', mask, params );

end

function per_freq(t, bounds, labs, mask, params)

cond_spec = 'stim_frequency';
per_condition( t, bounds, labs, cond_spec, {}, mask, params );

end

function per_freq_and_image_direction(t, bounds, labs, mask, params)

cond_spec = { 'stim_frequency', 'image_direction' };
per_condition( t, bounds, labs, cond_spec, 'stim_frequency', mask, params );

end

function per_condition(t, bounds, labs, cond_spec, fcats, mask, params)

cond_I = findall_or_one( labs, cond_spec, mask );

ps = [];
nulls = [];
p_labs = fcat();

diffs = [];
diff_labs = fcat();

for i = 1:numel(cond_I)
  run_I = findall( labs, 'unified_filename', cond_I{i} );

  [p, tmp_labs, tmp_diffs, tmp_null] = bfw_it.stim_minus_sham_fixation_decay( bounds, labs', run_I ...
    , 'seed', params.seed ...
  );

  append( p_labs, tmp_labs );
  append( diff_labs, repmat(tmp_labs', rows(tmp_diffs)) );
  
  ps = [ ps; p ];
  diffs = [ diffs; tmp_diffs ];
  nulls = [ nulls; tmp_null ];
end

plot_performance( t, ps, p_labs', nulls, diffs, diff_labs', cond_spec, fcats, params );

end

function plot_performance(t, ps, p_labs, nulls, diffs, diff_labs, spec, fcats, params)

[~, sort_I] = sortrows( diff_labs );
diffs = diffs(sort_I, :);

fig_I = findall_or_one( diff_labs, fcats );

for i = 1:numel(fig_I)

  [plot_I, plot_C] = findall( diff_labs, spec, fig_I{i} );
  sub_shape = plotlabeled.get_subplot_shape( numel(plot_I) );

  fig = figure(1);
  clf( fig );
  axs = gobjects( numel(plot_I), 1 );

  for j = 1:numel(plot_I)
    ax = subplot( sub_shape(1), sub_shape(2), j );

    subset_diff = diffs(plot_I{j}, :);
    mean_diff = nanmean( subset_diff, 1 );
    err_diff = plotlabeled.nansem( subset_diff );

    if ( params.plot_err )
      plot_mean_and_error( ax, t, mean_diff, err_diff );
    else
      plot( ax, t, mean_diff, 'linewidth', 1.5 );
      hold( ax, 'on' );
    end

    p_ind = find( p_labs, plot_C(:, j) );
    assert( numel(p_ind) == 1 );  
    
    add_stars( ax, t, ps(p_ind, :) );
    plot( ax, t, nulls(p_ind, :), 'r' );

    title_str = strjoin( plot_C(:, j), ' | ' );
    title_str = strrep( title_str, '_', ' ' );
    title( ax, title_str );

    axs(j) = ax;
  end

  shared_utils.plot.set_xlims( axs, [min(t), max(t)] );
  shared_utils.plot.set_ylims( axs, [-1, 1] );
  
  shared_utils.plot.match_ylims( axs );

%   shared_utils.plot.add_horizontal_lines( axs, 0 );
  shared_utils.plot.add_vertical_lines( axs, 0 );
  
  if ( params.do_save )    
    plot_p = get_plot_p( params );
    plot_labs = prune( diff_labs(fig_I{i}) );
    
    dsp3.req_savefig( fig, plot_p, plot_labs, csunion(spec, fcats) );
  end
end

end

function plot_p = get_plot_p(params, varargin)

plot_p = fullfile( bfw.dataroot(params.config), 'plots', 'stim', 'image_task' ...
  , 'fixation_decay', dsp3.datedir, params.base_subdir, varargin{:} );

end

function add_stars(ax, t, p)

sig_ps = find( p < 0.05 );

lims = get( ax, 'ylim' );

for i = 1:numel(sig_ps)
  plot( ax, t(sig_ps(i)), lims(2), 'k*' );
end

end

function plot_mean_and_error(ax, t, mean_diff, err_diff)

h_mean = plot( ax, t, mean_diff, 'linewidth', 1.5 );
hold( ax, 'on' );
h_err1 = plot( ax, t, mean_diff + err_diff );
h_err2 = plot( ax, t, mean_diff - err_diff );

set( h_err1, 'color', get(h_mean, 'color') );
set( h_err2, 'color', get(h_mean, 'color') );

end

function labels = handle_labels(labels)

bfw_it.add_stim_frequency_labels( labels );
bfw_it.decompose_image_id_labels( labels );

end

function mask = get_base_mask(labels)

mask = bfw_it.find_non_error_runs( labels );

end