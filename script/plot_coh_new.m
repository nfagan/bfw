conf = bfw.config.load();

conf.PATHS.data_root = get_nf_local_dataroot();

mats = bfw.rim( bfw.gid('summarized_raw_mtpower', conf) );

datedir = datestr( now, 'mmddyy' );
plot_p = fullfile( bfw.dataroot(conf), 'plots', 'spectra', datedir );

%%

select = @(x) only(x, {'eyes_nf', 'face'});

use_mats = mats;

[data, labs, freqs, t] = bfw.load_signal_measure( use_mats ...
  , 'get_measure',        @(x) select(summarized_measure(x)) ...
  , 'get_time',           @(x) x.t ...
  , 'get_freqs',          @(x) x.f ...
  , 'get_measure_type',   @(x) x.params.measure ...
  , 'check_continue',     @(x) false ...
);

prune( bfw.unify_region_labels(labs) );
prune( bfw.add_monk_labels(labs) );

%%  zscore

% zspec = { 'measure', 'region', 'channel', 'roi', 'looks_by' };
zspec = { 'measure', 'region', 'roi', 'channel', 'id_m2' };
zdat = bfw.zscore_each( data, labs, zspec );

%%  subtraction (eyes - face)

a = 'face';
b = 'eyes_nf';
sub_cats = 'roi';
lab_cat = 'roi';

%%  subtraction (mut - excl)

a = 'mutual';
b = 'm1';
sub_cats = { 'looks_by', 'initiator', 'event_type', 'id_m2' };
lab_cat = 'looks_by';

%% subtraction implementation

uselabs = labs';
usedat = zdat;

opfunc = @minus;
sfunc = @(x) nanmean(x, 1);

subspec = cssetdiff( getcats(uselabs), sub_cats );

[subdat, sublabs, I] = dsp3.summary_binary_op( usedat, uselabs' ...
  , subspec, a, b, opfunc, sfunc );

setcat( sublabs, lab_cat, sprintf('%s %s %s', a, func2str(opfunc), b) );

%%  subtractions, mult

as = { 'face', 'mutual' };
bs = { 'eyes_nf', 'm1' };

sub_cats = { 'roi', {'looks_by', 'initiator', 'event_type', 'id_m2'} };
lab_cats = { 'roi', 'looks_by' };

subdat = [];
sublabs = fcat();

for i = 1:numel(as)
  uselabs = labs';
  usedat = zdat;
  
  a = as{i};
  b = bs{i};
  lab_cat = lab_cats{i};

  opfunc = @minus;
  sfunc = @(x) nanmean(x, 1);

  subspec = cssetdiff( getcats(uselabs), sub_cats{i} );

  [tmp_subdat, tmp_sublabs, I] = dsp3.summary_binary_op( usedat, uselabs' ...
    , subspec, a, b, opfunc, sfunc );

  setcat( tmp_sublabs, lab_cat, sprintf('%s %s %s', a, func2str(opfunc), b) );
  addsetcat( tmp_sublabs, 'subtraction_type', sprintf('subtraction__%d', i) );
  
  append( sublabs, tmp_sublabs );
  subdat = [ subdat; tmp_subdat ];
end

%%  spectra

do_save = true;

mult_is_zscored = [true];
mult_is_subtracted = [true, false];
mult_is_matched = [true, false];
mult_is_per_m2 = [true, false];

inds = dsp3.numel_combvec( mult_is_zscored, mult_is_subtracted ...
  , mult_is_matched, mult_is_per_m2 );

base_subdir = 'without_0927';

for idx = 1:size(inds, 2)
  shared_utils.general.progress( idx, size(inds, 2) );
  
  subset_inds = inds(:, idx);
  
  is_zscored =    mult_is_zscored(subset_inds(1));
  is_subtracted = mult_is_subtracted(subset_inds(2));
  is_matched =    mult_is_matched(subset_inds(3));
  is_per_m2 =     mult_is_per_m2(subset_inds(4));  

  subdir = base_subdir;
  subdir = ternary( is_per_m2, sprintf('%s_per_monkey', subdir), subdir );
  subdir = ternary( is_matched, sprintf('%s_matched', subdir), subdir );

  if ( is_subtracted )
    pltlabs = sublabs';
    pltdat = subdat;
  else
    pltlabs = labs';
    pltdat = ternary( is_zscored, zdat, data );
  end

  t_ind = true( size(t) );
  f_ind = freqs <= 100;

  subt = t(t_ind);
  subf = freqs(f_ind);

  pl = plotlabeled.make_spectrogram( subf, subt );
  pl.sort_combinations = true;

  % pl.shape = [3, 1];
  % pl.c_lims = [ -0.06, 0.06 ];

  mask = fcat.mask( pltlabs ...
    , @(x, varargin) bfw.catfindnot_substr(x, 'region', varargin{:}), 'ref' ...
    , @findnone, 'face' ...
    , @findnone, 'm2' ...
    , @findnone, '09272018' ...
  );

% , @(x, varargin) bfw.catfind_substr(x, 'region', varargin{:}), 'bla' ...

  fcats = { 'measure', 'roi', 'region' };
  pcats = { 'region', 'roi', 'looks_by', 'measure' };

  if ( is_per_m2 )
    fcats = csunion( fcats, 'id_m2' );
  end
  
  if ( is_subtracted )
    fcats = csunion( fcats, 'subtraction_type' );
  end

  mdat = pltdat(mask, f_ind, t_ind);
  mlabs = pltlabs(mask);

  [f, axs, I] = pl.figures( @imagesc, mdat, mlabs, fcats, pcats );

  shared_utils.plot.tseries_xticks( axs, subt, 5 );
  shared_utils.plot.fseries_yticks( axs, round(flip(subf)), 10 );
  shared_utils.plot.hold( axs, 'on' );
  shared_utils.plot.add_vertical_lines( axs, find(subt == 0) );
  shared_utils.plot.fullscreen( f );

  if ( is_matched ), shared_utils.plot.match_clims( axs ); end

  if ( do_save )
    scats = cshorzcat( fcats, pcats );

    z_component = ternary( is_zscored, 'z', 'nonz' );
    sub_component = ternary( is_subtracted, 'subtracted', 'nonsubtracted' );

    full_plot_p = fullfile( plot_p, subdir, 'spectra', z_component, sub_component );

    for i = 1:numel(f)
      dsp3.req_savefig( f(i), full_plot_p, mlabs(I{i}), scats, 'spectra__' );
    end
  end
end

%%  band-means histogram

is_zscored = true;
is_subtracted = false;
do_save = true;
subdir = 't2';

if ( is_subtracted )
  uselabs = sublabs';
  usedat = subdat;
else
  uselabs = labs';
  usedat = ternary( is_zscored, zdat, data );
end

bands = { [0, 15], [15, 25], [45, 60] };
bandnames = { 'alpha', 'beta', 'gamma' };
time_rois = { [-250, 0], [0, 250] };
timenames = { 'pre0', 'post0' };

meaned_dat = [];
meaned_labs = fcat();

for i = 1:numel(timenames)
  t_ind = t >= time_rois{i}(1) & t <= time_rois{i}(2);
  
  time_meaned = squeeze( nanmean(usedat(:, :, t_ind), 3) );
  [banddat, bandlabs] = dsp3.get_band_means( time_meaned, uselabs', freqs, bands, bandnames );
  addsetcat( bandlabs, 'timebands', timenames{i} );
  
  meaned_dat = [ meaned_dat; banddat ];
  append( meaned_labs, bandlabs );
end

assert_ispair( meaned_dat, meaned_labs );

pl = plotlabeled.make_common();

fcats = { 'id_m2', 'timebands', 'region' };
pcats = { 'region', 'roi', 'looks_by', 'measure', 'bands', 'id_m2' };

mask = fcat.mask( meaned_labs ...
  , @(x, varargin) bfw.catfindnot_substr(x, 'region', varargin{:}), 'ref' ...
  , @(x, varargin) bfw.catfind_substr(x, 'region', varargin{:}), 'bla' ...
  , @findnone, 'face' ...
  , @findnone, 'm2' ...
  , @find, 'm2_hitch' ...
  , @findnone, {'09272018'} ...
);

[mlabs, I] = keepeach( meaned_labs' ...
  , { 'measure', 'roi', 'id_m2', 'channel', 'region', 'looks_by' ...
  , 'unified_filename', 'bands', 'timebands' }, mask );
mdat = rownanmean( meaned_dat, I );

% mdat = meaned_dat(mask);
% mlabs = meaned_labs(mask);

[f, axs, I] = pl.figures( @hist, mdat, mlabs, fcats, pcats, 100 );

shared_utils.plot.match_xlims( axs );

if ( do_save )
  shared_utils.plot.fullscreen( f );
  
  scats = cshorzcat( fcats, pcats );
  
  z_component = ternary( is_zscored, 'z', 'nonz' );
  sub_component = ternary( is_subtracted, 'subtracted', 'nonsubtracted' );
  
  full_plot_p = fullfile( plot_p, subdir, 'hists', z_component, sub_component );
  
  for i = 1:numel(f)
    dsp3.req_savefig( f(i), full_plot_p, mlabs(I{i}), scats, 'hist__' );
  end
end

%%  lines

pltlabs = labs';
pltdat = zdat;

is_over_t = false;

t_ind = t >= -100 & t <= 0;
f_ind = freqs <= 100;

subt = t(t_ind);
subf = freqs(f_ind);

pl = plotlabeled.make_common();
pl.add_errors = false;
pl.x = ternary( is_over_t, subt, subf );

mean_dim = ternary( is_over_t, 2, 3 );

mask = fcat.mask( pltlabs ...
  , @find, {'m1'} ...
  , @(x, l, m) bfw.catfindnot_substr(x, 'region', l, m), 'ref' ...
);

fcats = { 'measure' };
gcats = { 'region' };
pcats = { 'roi', 'looks_by', 'measure' };

mdat = squeeze( nanmean(pltdat(mask, f_ind, t_ind), mean_dim) );
mlabs = pltlabs(mask);

[f, axs] = pl.figures( @lines, mdat, mlabs, fcats, gcats, pcats );

xlab = ternary( is_over_t, 'Time (ms)', 'Hz' );

shared_utils.plot.xlabel( axs, xlab );

%%  bar - means

pltlabs = sublabs';
pltdat = subdat;

t_ind = t >= -100 & t <= 0;
f_ind = freqs <= 100;

mask = fcat.mask( pltlabs ...
  , @find, {'m1'} ...
  , @(x, l, m) bfw.catfindnot_substr(x, 'region', l, m), 'ref' ...
  , @find, {'acc_bla', 'bla_dmpfc', 'bla_ofc'} ...
);

xcats = { 'looks_by', 'roi' };
gcats = { 'region' };
pcats = { 'measure' };
fcats = { 'measure' };

mdat = squeeze( nanmean(nanmean(pltdat(mask, f_ind, t_ind), 2), 3) );
mlabs = pltlabs(mask);

pl = plotlabeled.make_common();
pl.error_func = @(x) 0;
pl.x_tick_rotation = 0;
pl.add_errors = true;

[f, axs] = pl.figures( @bar, mdat, mlabs, fcats, xcats, gcats, pcats );


