conf = bfw.config.load();

conf.PATHS.data_root = get_nf_local_dataroot();

mats = bfw.rim( bfw.gid('summarized_raw_coherence', conf) );

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

%%  zscore

% zspec = { 'measure', 'region', 'channel', 'roi', 'looks_by' };
zspec = { 'measure', 'region' };
zdat = bfw.zscore_each( data, labs, zspec );

%%  subtraction (eyes - face)

a = 'eyes_nf';
b = 'face';
sub_cats = 'roi';
lab_cat = 'roi';

%%  subtraction (mut - excl)

a = 'mutual';
b = 'm1';
sub_cats = { 'looks_by', 'initiator', 'event_type' };
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

%%  spectra

pltlabs = sublabs';
pltdat = subdat;

t_ind = true( size(t) );
f_ind = freqs <= 100;

subt = t(t_ind);
subf = freqs(f_ind);

pl = plotlabeled.make_spectrogram( subf, subt );

mask = fcat.mask( pltlabs ...
  , @find, 'm1' ...
  , @(x, varargin) bfw.catfindnot_substr(x, 'region', varargin{:}), 'ref' ...
  , @(x, varargin) bfw.catfind_substr(x, 'region', varargin{:}), 'bla' ...
  , @findnot, 'bla_dmpfc' ...
);

fcats = { 'measure' };
pcats = { 'region', 'roi', 'looks_by', 'measure' };

mdat = pltdat(mask, f_ind, t_ind);
mlabs = pltlabs(mask);

[f, axs] = pl.figures( @imagesc, mdat, mlabs, fcats, pcats );

shared_utils.plot.tseries_xticks( axs, subt, 5 );
shared_utils.plot.fseries_yticks( axs, round(flip(subf)), 10 );
shared_utils.plot.hold( axs, 'on' );
shared_utils.plot.add_vertical_lines( axs, find(subt == 0) );

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


