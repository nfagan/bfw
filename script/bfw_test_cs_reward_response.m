conf = bfw.config.load();

reward_response = bfw_get_cs_reward_response( ...
    'event_names', {'cs_presentation', 'cs_reward'} ...
  , 'bin_size', 0.01 ...
  , 'is_firing_rate', false ...
  , 'spike_dir', 'cc_spikes' ...
  , 'is_parallel', true ...
  , 'config', conf ...
);

%%

time_mask = reward_response.t >= 0.0 & reward_response.t < 0.5;
psth = nanmean( reward_response.psth(:, time_mask), 2 );

%% anova low v medium v high

anova_mask = fcat.mask( reward_response.labels ...
  , @findnone, 'reward-NaN' ...
);

anovas_each = { 'event-name', 'unit_uuid', 'region', 'session', 'unit-number' };
anova_factor = 'reward-level';

anova_outs = dsp3.anova1( psth, reward_response.labels', anovas_each, anova_factor ...
  , 'mask', anova_mask ...
);

anova_p = cellfun( @(x) x.Prob_F{1}, anova_outs.anova_tables );
anova_labels = anova_outs.anova_labels';
addsetcat( anova_labels, 'sig', 'sig-true', find(anova_p < 0.05) );

%%  ttest low v high

t_mask = fcat.mask( reward_response.labels ...
  , @findnone, 'reward-NaN' ...
);

t_each = { 'event-name', 'unit_uuid', 'region', 'session', 'unit-number' };

t_out = dsp3.ttest2( psth, reward_response.labels', t_each, 'reward-1', 'reward-3' ...
  , 'mask', t_mask ...
);

t_p = cellfun( @(x) x.p, t_out.t_tables );
t_labels = addcat( t_out.t_labels', 'comparison' );

cs_pres_ind = find( t_labels, 'cs_presentation' );
cs_reward_ind = find( t_labels, 'cs_reward' );
is_sig = t_p < 0.05;
sig_cs_pres = is_sig(cs_pres_ind);
sig_reward = is_sig(cs_reward_ind);
is_sig = sig_cs_pres | sig_reward;
t_labels = addsetcat( t_labels(cs_pres_ind), 'sig', 'sig-true', find(is_sig) );

% cs_labs = t_out.t_labels(cs_pres_ind);
% rw_labs = t_out.t_labels(cs_reward_ind);

% addsetcat( t_labels, 'sig', 'sig-true', find(t_p < 0.05) );

%%

soc_anova_labs = bfw_ct.load_significant_social_cell_labels_from_anova( conf, true );
sig_anova_ind = find( soc_anova_labs, 'significant' );

sig_selectors = combs( soc_anova_labs, {'unit_uuid', 'region', 'session'}, sig_anova_ind );
t_selectors = combs( t_labels, {'unit_uuid', 'region', 'session'} );

sig_select = categorical( sig_selectors )';
t_select = categorical( t_selectors )';
% all_select = cellstr( union(sig_select, t_select, 'rows') );
all_select = cellstr( t_select );

unique_reg = unique( all_select(:, 2) );

n_t = zeros( numel(unique_reg), 1 );
n_anova = zeros( size(n_t) );
n_both = zeros( size(n_t) );

for i = 1:size(all_select, 1)
  is_t = ~isempty( find(t_labels, all_select(i, :), find(t_labels, 'sig-true')) );
  is_anova = ~isempty( find(soc_anova_labs, all_select(i, :), sig_anova_ind) );
  reg_ind = find( strcmp(unique_reg, all_select{i, 2}) );

  if ( is_t && is_anova )
    n_both(reg_ind) = n_both(reg_ind) + 1;
  elseif ( is_t )
    n_t(reg_ind) = n_t(reg_ind) + 1;
  elseif ( is_anova )
    n_anova(reg_ind) = n_anova(reg_ind) + 1;
  end
end

%%

clf;

axs = [];
for i = 1:4
  ax = subplot( 2, 2, i )
  venn( [n_t(i) + n_both(i), n_anova(i) + n_both(i)], n_both(i) );
  title( unique_reg{i} );
  axs(i) = ax;
end

shared_utils.plot.match_xlims( axs );
shared_utils.plot.match_ylims( axs );

%%

do_save = true;

method_labels = [ addsetcat(anova_labels', 'method', 'anova'); ...
                  addsetcat(t_labels', 'method', 'ttest (low v high)') ];
[props, prop_labels] = proportions_of( method_labels, {'event-name', 'region', 'method'}, 'sig' );

pl = plotlabeled.make_common();

plt_mask = fcat.mask( prop_labels, @find, 'sig-true', @findnot, 'anova' );
plt = props(plt_mask);
plt_labels = prop_labels(plt_mask);

xcats = { 'region' };
gcats = { 'sig' };
pcats = { 'method', 'event-name' };
[axs, ids] = pl.bar( plt * 1e2, plt_labels, xcats, gcats, pcats );
ylabel( axs(1), '% Significant' );

if ( do_save )
  save_p = fullfile( bfw.dataroot(conf), 'plots/cs_psth/stats', dsp3.datedir );
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, plt_labels, unique([xcats, gcats, pcats]) );
end
