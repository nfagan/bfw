function bfw_plot_image_task_fix_info(fix_outs, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
params = bfw.parsestruct( defaults, varargin );

labs = fix_outs.labels';
fix_info = fix_outs.fix_info;

assert_ispair( fix_info, labs );

handle_labels( labs );
mask = get_base_mask( labs );

totaldur = fix_info(:, 2);

plot_total_duration_over_blocks( totaldur, labs', mask, params );
plot_total_duration( totaldur, labs', mask, params );
plot_n_fix( fix_info(:, 1), labs', mask, params );
plot_fix_dur( totaldur, labs', mask, params );

end

function nums = parse_run_numbers(run_numbers)

nums = cellfun( @(x) str2double(x(numel('run_number-')+1:end)), run_numbers );

end

function plot_total_duration_over_blocks(total_dur, labs, mask, params)

%%
% sum_spec = { 'unified_filename', 'stim_frequency', 'stim_type' };
% [dur_labs, I] = keepeach( labs', sum_spec, mask );
% summarized_dur = bfw.row_nanmean( total_dur, I );

summarized_dur = total_dur(mask);
dur_labs = prune( labs(mask) );

run_nums_str = combs( dur_labs, 'run_number' );
run_nums = parse_run_numbers( run_nums_str );
[~, sorted_i] = sort( run_nums );

pl = plotlabeled.make_common();
pl.summary_func = @nanmedian;
pl.x_order = run_nums_str(sorted_i);
pl.add_errors = true;

xcats = { 'run_number' };
gcats = { 'stim_type' };
pcats = { 'stim_frequency', 'session' };

pltdat = summarized_dur;
pltlabs = dur_labs;

axs = pl.bar( pltdat, pltlabs, xcats, gcats, pcats );
ylabel( axs(1), 'Looking duration (ms)' );

if ( params.do_save )
  save_p = get_plot_p( params, 'total_dur_over_runs' );
  dsp3.req_savefig( gcf, save_p, pltlabs, pcats );
end


end

function plot_n_fix(nfix, labs, mask, params)
%%
pl = plotlabeled.make_common();

xcats = { 'stim_frequency' };
gcats = { 'stim_type' };
% pcats = { 'image_monkey' };
pcats = {};

pltdat = nfix(mask);
pltlabs = prune( labs(mask) );

axs = pl.bar( pltdat, pltlabs, xcats, gcats, pcats );
ylabel( axs(1), 'N fixations' );

if ( params.do_save )
  save_p = get_plot_p( params, 'n_fix' );
  dsp3.req_savefig( gcf, save_p, pltlabs, pcats );
end

end

function plot_total_duration(fixdur, labs, mask, params)

%%
pl = plotlabeled.make_common();
pl.summary_func = @nanmedian;
pl.add_points = true;
pl.marker_size = 4;

% sum_spec = { 'unified_filename', 'stim_frequency', 'stim_type' };
sum_spec = { 'session', 'stim_frequency', 'stim_type' };

[dur_labs, I] = keepeach( labs', sum_spec, mask );

total_dur = bfw.row_nanmean( fixdur, I );

xcats = { 'stim_frequency' };
gcats = { 'stim_type' };
% pcats = { 'image_monkey' };
pcats = {};

pltdat = total_dur;
pltlabs = dur_labs;

axs = pl.bar( pltdat, pltlabs, xcats, gcats, pcats );
ylabel( axs(1), 'Looking duration (ms)' );

if ( params.do_save )
  save_p = get_plot_p( params, 'total_dur' );
  dsp3.req_savefig( gcf, save_p, pltlabs, pcats );
end


end

function plot_fix_dur(fixdur, labs, mask, params)

%%
pl = plotlabeled.make_common();
pl.summary_func = @nanmedian;

xcats = { 'stim_frequency' };
gcats = { 'stim_type' };
% pcats = { 'image_monkey' };
pcats = {};

pltdat = fixdur(mask);
pltlabs = prune( labs(mask) );

axs = pl.bar( pltdat, pltlabs, xcats, gcats, pcats );
ylabel( axs(1), 'Fixation duration (ms)' );

if ( params.do_save )
  save_p = get_plot_p( params, 'fix_dur' );
  dsp3.req_savefig( gcf, save_p, pltlabs, pcats );
end

end

function p = get_plot_p(params, varargin)

p = fullfile( bfw.dataroot(params.config), 'plots', 'stim', 'image_task' ...
  , 'behavior', dsp3.datedir, params.base_subdir, varargin{:} );

end

function handle_labels(labs)

bfw_it.add_stim_frequency_labels( labs );
bfw_it.decompose_image_id_labels( labs );
bfw_it.add_run_number( labs );

end

function mask = get_base_mask(labels)

mask = bfw_it.find_non_error_runs( labels );

end