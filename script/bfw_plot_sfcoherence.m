conf = bfw.config.load();
conf.PATHS.data_root = '~/Desktop/bfw/';

sfcoh_types = { '1channel_meta', '1channel_mouth', '1channel_object' };
sfcoh_subdirs = cellfun( @(x) fullfile('sfcoherence', x), sfcoh_types, 'un', 0 );

mats = shared_utils.io.findmat( bfw.gid(sfcoh_subdirs, conf) );

[coh, labels, freqs, t] = bfw.load_time_frequency_measure( mats );
bfw.unify_single_region_labels( labels );
nanmean1 = bind1( @nanmean, 1 );

%%

plot_p = fullfile( bfw.dataroot, 'plots', 'spectra', dsp3.datedir );

%%

summary_labels = bfw.add_region_pair_labels( labels' );

summary_spec = { 'spike_region', 'spike_channel', 'region', 'channel' ...
  , 'roi', 'looks_by', 'session' };
[~, I] = keepeach( summary_labels, summary_spec );

summary_coh = rowop( coh, I, nanmean1 );

%%  subtract mult

copy_labels = bfw.add_region_pair_labels( labels' );
copy_coh = coh;

sub_spec = summary_spec;

pairs = { {'mutual', 'm1'}, {'eyes_nf', 'mouth'} };

sub_coh = [];
sub_labels = fcat();

for i = 1:numel(pairs)

  a = pairs{i}{1};
  b = pairs{i}{2};

  sub_cat = whichcat( copy_labels, a );

  [tmp_coh, tmp_labels] = dsp3.summary_binary_op( copy_coh, copy_labels' ...
    , setdiff(sub_spec, sub_cat), a, b, @minus, nanmean1 );
  
  addsetcat( tmp_labels, 'subtract_category', sprintf('subtract_%s', char(sub_cat)) );

  setcat( tmp_labels, sub_cat, sprintf('%s-%s', a, b) );
  
  append( sub_labels, tmp_labels );
  sub_coh = [ sub_coh; tmp_coh ];
end

%%  double subtract

sub_labels = bfw.add_region_pair_labels( labels' );
sub_coh = coh;

sub_spec = summary_spec;

pairs = { {'mutual', 'm1'}, {'eyes_nf', 'everywhere'} };

for i = 1:numel(pairs)

  a = pairs{i}{1};
  b = pairs{i}{2};

  sub_cat = whichcat( sub_labels, a );

  [sub_coh, sub_labels] = dsp3.summary_binary_op( sub_coh, sub_labels ...
    , setdiff(sub_spec, sub_cat), a, b, @minus, nanmean1 );

  setcat( sub_labels, sub_cat, sprintf('%s-%s', a, b) );
end


%%

do_save = true;
is_subtracted = true;
base_prefix = '';
base_subdir = 'mut_minus_excl_reg_matched';
% base_subdir = 'eyes_minus_outside_one_panel';
% base_subdir = 'eyes_minus_mouth_one_panel';
match_fig_limits = true;
stretch_fig_limits = true;
clims = [];
t_window = [ -300, 300 ];
f_window = [ 10, 100 ];

if ( is_subtracted )
  plt_coh = sub_coh;
  plt_labels = sub_labels';
else
  plt_coh = coh;
  plt_labels = bfw.add_region_pair_labels( labels' );
end

assert_ispair( plt_coh, plt_labels );

% mask = fcat.mask( plt_labels ...
%   , @find, {'subtract_roi', 'm1'} ...
%   , @find, {'bla_dmpfc'} ...
% );

mask = fcat.mask( plt_labels ...
  , @find, {'subtract_looks_by', 'eyes_nf'} ...
  , @find, {'acc_bla'} ...
);

% fcats = { 'region_pair' };
fcats = { 'region', 'spike_region', 'subtract_category' };
pcats = { 'looks_by', 'roi', 'region', 'spike_region' };

if ( ~isempty(f_window) )
  f_ind = freqs >= f_window(1) & freqs <= f_window(2);
else
  f_ind = true( size(freqs) );
end

if ( ~isempty(t_window) )
  t_ind = t >= t_window(1) & t <= t_window(2);
else
  t_ind = true( size(t) );
end

pl = plotlabeled.make_spectrogram( freqs(f_ind), t(t_ind) );
pl.sort_combinations = true;

fig_I = findall( plt_labels, fcats, mask );
figs = cell( numel(fig_I), 1 );
all_axs = cell( numel(fig_I), 1 );

plt_freqs = pipe( freqs(f_ind), @flip, @round );

for i = 1:numel(fig_I)
  f = figure(i);
  clf( f );
  pl.fig = f;
  figs{i} = f;
  
  subset_coh = plt_coh(fig_I{i}, f_ind, t_ind);
  subset_labs = plt_labels(fig_I{i});

  axs = pl.imagesc( subset_coh, subset_labs, pcats );

  shared_utils.plot.fseries_yticks( axs, plt_freqs, 5 );
  shared_utils.plot.tseries_xticks( axs, t(t_ind), 3 );
  
  all_axs{i} = axs;
end

combined_axs = [ all_axs{:} ];

if ( ~isempty(clims) )
  shared_utils.plot.set_clims( combined_axs, clims );
  
elseif ( match_fig_limits )
  shared_utils.plot.match_clims( combined_axs );
end

if ( stretch_fig_limits )
  shared_utils.plot.hold( combined_axs, 'on' );
  dsp3.stretch_spectral_ylimits( combined_axs, plt_freqs, 10, 100, true );
end

if ( do_save )
  for i = 1:numel(fig_I)
    f = figs{i};
    axs = all_axs{i};
    
    formats = { 'epsc', 'png', 'fig', 'svg' };
    plt_cats = unique( cshorzcat(fcats, pcats) );
    prefix = base_prefix;
    full_plot_p = fullfile( plot_p, base_subdir );
    
    subset_labs = prune( plt_labels(fig_I{i}) );

    shared_utils.plot.fullscreen( f );
    shared_utils.plot.hold( axs, 'on' );
    shared_utils.plot.add_vertical_lines( axs, find(t(t_ind) == 0) );
    fname = dsp3.req_savefig( f, full_plot_p, subset_labs, plt_cats, prefix, formats );
  end
end