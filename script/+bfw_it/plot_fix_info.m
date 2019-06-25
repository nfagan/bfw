function plot_fix_info(fix_outs, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.mask = rowmask( fix_outs.labels );
params = bfw.parsestruct( defaults, varargin );

labels = fix_outs.labels';

handle_labels( labels );
mask = get_base_mask( labels, params.mask );

kinds = { 'total_duration', 'n_fix' };
[has_key, columns] = ismember( kinds, fix_outs.fix_info_key );

assert( all(has_key), 'Key is missing entry(ies): %s', strjoin(kinds(~has_key)) );

for i = 1:numel(kinds)
  use_dat = fix_outs.fix_info(:, columns(i));

  plot_each_session_over_runs( use_dat, labels', mask, kinds{i}, params );
  plot_design_types_over_runs( use_dat, labels', mask, kinds{i}, params );
  plot_compare_sham_types_over_runs( use_dat, labels', mask, kinds{i}, params );
end

end


function plot_compare_sham_types_over_runs(data, labels, mask, kind, params)

import shared_utils.plot.label_str;

assert_ispair( data, labels );
assert( isvector(data) );

% Only block or no stimulation blocks, only sham.
mask = fcat.mask( labels, mask ...
  , @find, 'block' ...
  , @find, 'sham' ...
);

figs_each = { 'roi' };
fig_I = findall_or_one( labels, figs_each, mask );

for i = 1:numel(fig_I)
  fig = gcf();
  clf( fig );
  
  fig_ind = fig_I{i};
  
  pl = plotlabeled.make_common();
  pl.fig = fig;
  pl.x_order = get_sorted_run_numbers( labels, fig_ind );
  pl.errorbar_connect_non_nan = true;
  
  xcats = { 'run_number' };
  pcats = { 'block_design', 'stim_type', 'block_design', 'roi' };
  gcats = { 'region' };
  
  pltdat = data(fig_ind);
  pltlabs = prune( labels(fig_ind) );
  
  axs = pl.errorbar( pltdat, pltlabs, xcats, gcats, pcats );
  ylabel( axs(1), label_str(kind) );
  
  if ( params.do_save )
    save_p = get_save_p( params, kind, 'by_sham_type' );
    shared_utils.plot.fullscreen( fig );
    dsp3.req_savefig( fig, save_p, pltlabs, [pcats, figs_each] );
  end
end

end

function plot_design_types_over_runs(data, labels, mask, kind, params)

import shared_utils.plot.label_str;

assert_ispair( data, labels );
assert( isvector(data) );

figs_each = { 'stim_frequency', 'roi' };
fig_I = findall_or_one( labels, figs_each, mask );

for i = 1:numel(fig_I)
  fig = gcf();
  clf( fig );
  
  fig_ind = fig_I{i};
  
  pl = plotlabeled.make_common();
  pl.fig = fig;
  pl.x_order = get_sorted_run_numbers( labels, fig_ind );
  pl.errorbar_connect_non_nan = true;
  
  xcats = { 'run_number' };
  pcats = { 'region', 'stim_frequency', 'block_design' };
  gcats = { 'stim_type' };
  
  pltdat = data(fig_ind);
  pltlabs = prune( labels(fig_ind) );
  
  axs = pl.errorbar( pltdat, pltlabs, xcats, gcats, pcats );
  ylabel( axs(1), label_str(kind) );
  
  if ( params.do_save )
    save_p = get_save_p( params, kind, 'by_block_design' );
    shared_utils.plot.fullscreen( fig );
    dsp3.req_savefig( fig, save_p, pltlabs, [pcats, figs_each] );
  end
end

end

function plot_each_session_over_runs(data, labels, mask, kind, params)

import shared_utils.plot.label_str;

assert_ispair( data, labels );
assert( isvector(data) );

figs_each = { 'session', 'roi' };
fig_I = findall( labels, figs_each, mask );

for i = 1:numel(fig_I)
  fig = gcf();
  clf( fig );
  
  fig_ind = fig_I{i};
  
  pl = plotlabeled.make_common();
  pl.fig = fig;
  pl.x_order = get_sorted_run_numbers( labels, fig_ind );
  pl.errorbar_connect_non_nan = true;
  
  xcats = { 'run_number' };
  gcats = { 'stim_type' };
  pcats = { 'region', 'session', 'stim_frequency', 'roi' };
  
  pltdat = data(fig_ind);
  pltlabs = prune( labels(fig_ind) );
  
  axs = pl.errorbar( pltdat, pltlabs, xcats, gcats, pcats );
  
  ylabel( axs(1), label_str(kind) );
%   shared_utils.plot.set_ylims( axs, [0, 5.5e3] );
  
  if ( params.do_save )
    save_p = get_save_p( params, kind, 'per_session' );
    shared_utils.plot.fullscreen( fig );
    dsp3.req_savefig( fig, save_p, pltlabs, [pcats, figs_each] );
  end
end

end

function [run_number_strs, run_nums] = get_sorted_run_numbers(labels, mask)

run_number_strs = combs( labels, 'run_number', mask );
run_nums = bfw_it.parse_run_numbers( run_number_strs );
[~, sorted_I] = sort( run_nums );
run_number_strs = run_number_strs(sorted_I);
run_nums = run_nums(sorted_I);

end

function save_p = get_save_p(params, varargin)

save_p = fullfile( bfw.dataroot(params.config), 'plots', 'stim_fix_info' ...
  , dsp3.datedir, params.base_subdir, varargin{:} );

end

function labs = handle_labels(labs)

bfw_it.decompose_image_id_labels( labs );
bfw_it.add_run_number( labs );

end

function mask = get_base_mask(labs, mask)

mask = bfw_it.find_non_error_runs( labs, mask );

end