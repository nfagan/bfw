function outs = stim_amp_vs_vel_stats(amp_vel_outs, varargin)

defaults.iters = 1e3;
defaults.seed = [];
defaults.mask_func = @(l, m) m;

params = bfw.parsestruct( defaults, varargin );

iters = params.iters;
seed = params.seed;

amps = amp_vel_outs.amps;
vels = amp_vel_outs.velocities;
labels = amp_vel_outs.labels';

handle_labels( labels );
mask = get_base_mask( labels, params.mask_func );

stats_each = { 'region', 'stim_protocol', 'task_type', 'id_m1' };
stats_I = findall_or_one( labels, stats_each, mask );

ps = cell( numel(stats_I), 1 );
labs = cell( size(ps) );

parfor i = 1:numel(stats_I)
  shared_utils.general.progress( i, numel(stats_I) );
  [ps{i}, labs{i}] = run_stats( amps, vels, labels', stats_I{i}, iters, seed );
end

ps = vertcat( ps{:} );
labs = vertcat( fcat, labs{:} );

outs = struct();
outs.ps = ps;
outs.labels = labs;

end

function [p, labs] = run_stats(amps, vels, labels, mask, iters, seed)

if ( ~isempty(seed) )
  rng_state = rng( seed );
end

mask = intersect( mask, find(~isnan(amps) & ~isnan(vels)) );

stim_ind = find( labels, 'stim', mask );
sham_ind = find( labels, 'sham', mask );
sample_ind = sort( [stim_ind; sham_ind] );

real_diff = beta_difference( amps, vels, stim_ind, sham_ind );
ps = zeros( iters, 1 );

for i = 1:iters
  shuff_ind = sample_ind(randperm(numel(sample_ind)));
  stim_ind = shuff_ind(1:numel(stim_ind));
  sham_ind = shuff_ind(numel(stim_ind)+1:end);
  
  beta_diff = beta_difference( amps, vels, stim_ind, sham_ind );
  ps(i) = beta_diff > real_diff;
end

p = sum( ps ) / iters;
labs = append1( fcat(), labels, mask );

if ( ~isempty(seed) )
  rng( rng_state );
end

end

function beta_diff = beta_difference(amps, vels, stim_ind, sham_ind)

stim_beta = run_model( amps, vels, stim_ind );
sham_beta = run_model( amps, vels, sham_ind );

beta_diff = abs( stim_beta - sham_beta );

end

function beta = run_model(amps, vels, ind)

model = fitlm( amps(ind), vels(ind) );
beta = model.Coefficients.Estimate(2);

end

function mask = get_base_mask(labels, mask_func)

mask = mask_func( labels, rowmask(labels) );

end

function labels = handle_labels(labels)

prune( bfw.get_region_labels(labels) );
prune( bfw.add_monk_labels(labels) );

end

% specs = { {}, {'id_m1'} };
% 
% for idx = 1:numel(specs)
% 
%   fcats = { 'region', 'stim_protocol' };
%   gcats = { 'stim_type' };
%   pcats = { 'task_type', 'region', 'stim_protocol' };
%   
%   fcats = [ fcats, specs{idx} ];
%   pcats = [ pcats, specs{idx} ];
% 
%   I = findall( pltlabs, fcats, mask );
% 
%   all_axs = [];
%   figs = gobjects( numel(I), 1 );
%   figlabs = cell( size(figs) );
% 
%   for i = 1:numel(I)
%     pltx = X(I{i});
%     plty = Y(I{i});
% 
%     nan_ind = isnan( pltx ) | isnan( plty );
% 
%     pltx = pltx(~nan_ind);
%     plty = plty(~nan_ind);
%     plt_labs = pltlabs(I{i}(~nan_ind));
% 
%     pl.fig = figure(i);
% 
%     [axs, ids] = pl.scatter( pltx, plty, plt_labs, gcats, pcats );
% 
% end