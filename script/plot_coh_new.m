conf = bfw.config.load();

% conf.PATHS.data_root = get_nf_local_dataroot();

mats = bfw.rim( bfw.gid('summarized_raw_coherence', conf) );

datedir = datestr( now, 'mmddyy' );
plot_p = fullfile( bfw.dataroot(conf), 'plots', 'spectra', datedir );

%%

select = @(x) only(x, {'eyes_nf', 'face', 'left_nonsocial_object', 'right_nonsocial_object', 'mouth'});

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

%%  n-sites - per pair

uselabs = labs';

[reglabs, I] = keepeach( uselabs', 'region' );
ndat = rowzeros( numel(I) );

for i = 1:numel(I)
  ndat(i) = numel( findall(uselabs, {'channel', 'session'}, I{i}) );  
end

[t_ind, rc] = tabular( reglabs, 'region', 'id_m1' );

tbl = fcat.table( cellrefs(ndat, t_ind), rc{:} );

%%  zscore

zspec = { 'measure', 'region', 'roi', 'channel', 'id_m2' };
zdat = bfw.zscore_each( data, labs, zspec );

%%  subtractions, mult

% as = { 'eyes_nf', 'mutual', 'm1_initiated' };
% bs = { 'face', 'm1', 'm2_initiated' };
% 
% sub_cats = { 'roi', {'looks_by', 'initiator', 'event_type', 'id_m2'} ...
%   , {'looks_by', 'event_type', 'id_m2'} };
% lab_cats = { 'roi', 'looks_by', 'initiator' };

as = { 'm1_initiated' };
bs = { 'm2_initiated' };
sub_cats = { {'event_type', 'id_m2', 'initiator', 'terminator'} };
lab_cats = { 'initiator' };

% as = { 'eyes_nf' };
% bs = { 'mouth' };
% 
% sub_cats = { 'roi' };
% lab_cats = { 'roi' };

assert( isequal(numel(as), numel(bs), numel(sub_cats), numel(lab_cats)) ...
  , 'Subtraction specifiers do not match.' );

subdat = [];
sublabs = fcat();

for i = 1:numel(as)
  shared_utils.general.progress( i, numel(as) );
  
  uselabs = labs';
  usedat = zdat;
  
  mask = fcat.mask( uselabs ...
    , @(x, varargin) bfw.catfindnot_substr(x, 'region', varargin{:}), 'ref' ...
    , @find, 'mutual' ...
  );
  
  a = as{i};
  b = bs{i};
  lab_cat = lab_cats{i};

  opfunc = @minus;
  sfunc = @(x) nanmean(x, 1);

  subspec = cssetdiff( getcats(uselabs), sub_cats{i} );

  [tmp_subdat, tmp_sublabs, I] = dsp3.summary_binary_op( usedat, uselabs' ...
    , subspec, a, b, opfunc, sfunc, mask );

  setcat( tmp_sublabs, lab_cat, sprintf('%s %s %s', a, func2str(opfunc), b) );
  addsetcat( tmp_sublabs, 'subtraction_type', sprintf('subtraction__%d', i) );
  
  append( sublabs, tmp_sublabs );
  subdat = [ subdat; tmp_subdat ];
end


%%

axs = findobj( figure(1), 'type', 'axes' );
shared_utils.plot.set_clims( axs, [-0.2, 0.42] );

figure(2);
clf();

acc_ind = find( sublabs, {'accg_bla', 'eyes_nf', 'mutual'} );
acc_ind = findnone( sublabs, '09272018', acc_ind );
ta_ind = freqs >= 4 & freqs <= 13;
meaned = squeeze( nanmean(subdat(:, ta_ind, :), 2) );
full_meaned = nanmean( meaned(acc_ind, :), 1 );

plot( t, full_meaned );

%%  spectra

do_save = false;

mult_is_zscored = [true];
mult_is_subtracted = [true];
mult_is_matched = [false];
mult_is_per_m2 = [false];
mult_is_per_initiator = [false];

inds = dsp3.numel_combvec( mult_is_zscored, mult_is_subtracted ...
  , mult_is_matched, mult_is_per_m2, mult_is_per_initiator );

base_subdir = 'without_0927';

scats = { 'measure', 'roi' };

for idx = 1:size(inds, 2)
  shared_utils.general.progress( idx, size(inds, 2) );
  
  subset_inds = inds(:, idx);
  
  is_zscored =    mult_is_zscored(subset_inds(1));
  is_subtracted = mult_is_subtracted(subset_inds(2));
  is_matched =    mult_is_matched(subset_inds(3));
  is_per_m2 =     mult_is_per_m2(subset_inds(4));  
  is_per_initiator = mult_is_per_initiator(subset_inds(5));

  subdir = base_subdir;
  subdir = ternary( is_per_m2, sprintf('%s_per_monkey', subdir), subdir );
  subdir = ternary( is_matched, sprintf('%s_matched', subdir), subdir );
  subdir = ternary( is_per_initiator, sprintf('%s_per_initiator', subdir), subdir );

  if ( is_subtracted )
    pltlabs = sublabs';
    pltdat = subdat;
  else
    pltlabs = labs';
    pltdat = ternary( is_zscored, zdat, data );
  end

  t_ind = true( size(t) );
%   f_ind = freqs <= 100;
  f_ind = freqs >= 4 & freqs <= 13;

  subt = t(t_ind);
  subf = freqs(f_ind);

  pl = plotlabeled.make_spectrogram( subf, subt );
  pl.sort_combinations = true;

  mask = fcat.mask( pltlabs ...
    , @(x, varargin) bfw.catfindnot_substr(x, 'region', varargin{:}), 'ref' ...
    , @findnone, 'face' ...
    , @findnone, 'm2' ...
    , @findnone, '09272018' ...
  );

  mask = fcat.mask( pltlabs, mask, @find, {'eyes_nf', 'accg_bla'} );

% , @(x, varargin) bfw.catfind_substr(x, 'region', varargin{:}), 'bla' ...

  fcats = { 'measure', 'roi', 'region' };
  pcats = { 'region', 'roi', 'looks_by', 'measure' };

  if ( is_per_m2 ), fcats = csunion( fcats, 'id_m2' ); end
  if ( is_subtracted ), fcats = csunion( fcats, 'subtraction_type' ); end
  if ( is_per_initiator ), fcats = csunion( fcats, 'initiator' ); end

  mdat = pltdat(mask, f_ind, t_ind);
  mlabs = pltlabs(mask);
  
  if ( is_matched )
    I2 = { mask };
  else
    I2 = findall( mlabs, fcats );
  end
  
  for j = 1:numel(I2)
    [f, axs, I] = pl.figures( @imagesc, mdat(I2{j}, :, :), mlabs(I2{j}), fcats, pcats );

    shared_utils.plot.tseries_xticks( axs, subt, 5 );
    shared_utils.plot.fseries_yticks( axs, round(flip(subf)), 10 );
    shared_utils.plot.hold( axs, 'on' );
    shared_utils.plot.add_vertical_lines( axs, find(subt == 0) );
    shared_utils.plot.fullscreen( f );

    if ( is_matched ), shared_utils.plot.match_clims( axs ); end

    if ( do_save )
      filename_cats = cshorzcat( fcats, pcats );

      z_component = ternary( is_zscored, 'z', 'nonz' );
      sub_component = ternary( is_subtracted, 'subtracted', 'nonsubtracted' );

      full_plot_p = fullfile( plot_p, subdir, 'spectra', z_component, sub_component );

      for i = 1:numel(f)
        ind = I2{j}(I{i});
        
        bfw.req_savefig_subdirs( scats, f(i), full_plot_p, prune(mlabs(ind)), filename_cats, 'spectra__' );
      end
    end
  end
end

%%  lines -- band-means

is_zscored = true;
is_per_initiator = true;
is_per_site = false;
match_initiators = true;
do_save = false;
is_smoothed = false;

prefix = 'compare_lines__';

uselabs = labs';
usedat = ternary( is_zscored, zdat, data );

bands = { [4, 13], [14, 25], [26, 55], [56, 80] };
bandnames = { 'theta-alpha', 'beta', 'gamma', 'high-gamma' };

[banddat, bandlabs] = dsp3.get_band_means( usedat, uselabs', freqs, bands, bandnames );

mask = fcat.mask( bandlabs ...
  , @(x, varargin) bfw.catfindnot_substr(x, 'region', varargin{:}), 'ref' ...
  , @(x, varargin) bfw.catfind_substr(x, 'region', varargin{:}), 'bla' ...
  , @findnone, {'m2', '09272018'} ...
  , @find, {'mutual', 'eyes_nf', 'm1'} ...
);

site_spec = { 'unified_filename', 'channel', 'region', 'bands', 'measure' };
mean_spec = csunion( site_spec, {'roi', 'id_m2', 'looks_by'} );

if ( is_per_initiator ), mean_spec{end+1} = 'initiator'; end

if ( is_per_site )
  [mlabs, I] = keepeach( bandlabs', mean_spec, mask );
  mdat = rownanmean( banddat, I );
else
  mlabs = prune( bandlabs(mask) );
  mdat = banddat(mask, :);
end

if ( match_initiators )
  I = findall( mlabs, subspec );
  to_keep = [];
  require = { 'm1_initiated', 'm2_initiated' };
  for i = 1:numel(I)
    if ( all(count(mlabs, require, I{i}) > 0) )
      to_keep = union( to_keep, I{i} );
    end
  end
  keep( mlabs, to_keep );
  mdat = rowref( mdat, to_keep );
end

%
%
%

fcats = { 'region' };
pcats = { 'region', 'roi', 'measure', 'bands' };

if ( is_per_initiator )
  gcats = { 'initiator' };
  pcats{end+1} = 'looks_by';
  prefix = sprintf( 'initiator_%s', prefix );  
  mask = fcat.mask( mlabs, @find, 'mutual', @findnone, 'simultaneous_start' );
else
  gcats = { 'looks_by' };
  mask = rowmask( mlabs );
end

smooth_func = ternary( is_smoothed, @(x) smooth(x, 3), @(x) x );
prefix = ternary( is_smoothed, sprintf('%s_smoothed__', prefix), prefix );

fig_I = findall( mlabs, fcats, mask );

f = gobjects( numel(fig_I), 1 );
all_axs = [];

for i = 1:numel(fig_I)
  f(i) = clf( figure(i) );
  
  axs = dsp3.plot_compare_lines( mdat, mlabs, gcats, pcats ...
    , 'mask', fig_I{i} ...
    , 'smooth_func', smooth_func ...
    , 'x', t ...
  );

  all_axs = [ all_axs; axs(:) ];
end

shared_utils.plot.match_ylims( all_axs );

if ( do_save )  
  plt_spec = unique( cshorzcat(fcats, pcats) );
  
  for i = 1:numel(f)
    shared_utils.plot.fullscreen( f(i) );
    dsp3.req_savefig( f(i), plot_p, mlabs(fig_I{i}), plt_spec, prefix );
  end
end

%%

I = findall( bandlabs, subspec, intersect(mask, find(bandlabs, 'mutual')) );
to_keep = [];

for i = 1:numel(I)
  if ( all(count(bandlabs, {'m1_initiated', 'm2_initiated'}, I{i}) > 0) )
    to_keep = union( to_keep, I{i} );
  end
end

%%

pl = plotlabeled.make_common();
pl.x = t;
pl.panel_order = bandnames;

fcats = { 'region' };
gcats = { 'bands' };
pcats = { 'region', 'roi', 'measure', 'looks_by' };

[f, axs, I] = pl.figures( @lines, mdat, mlabs, fcats, gcats, pcats );

shared_utils.plot.match_ylims( axs );

if ( do_save )  
  plt_spec = unique( cshorzcat(fcats, pcats) );
  
  for i = 1:numel(f)
    shared_utils.plot.fullscreen( f(i) );
    dsp3.req_savefig( f(i), plot_p, mlabs(I{i}), plt_spec, 'lines__' );
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

is_over_t = true;

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


