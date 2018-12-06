conf = bfw.config.load();

load_p = '/Users/Nick/Desktop';

load( fullfile(load_p, 'tmp_coh.mat') );
load( fullfile(load_p, 'tmp_coh_tf.mat') );
load( fullfile(load_p, 'tmp_coh_labs.mat') );

datedir = datestr( now, 'mmddyy' );
plot_p = fullfile( bfw.dataroot(conf), 'plots', 'spectra', datedir );

%%  zscore

zspec = { 'measure', 'region', 'roi', 'channel', 'id_m2' };
zdat = bfw.zscore_each( data, labs, zspec );

%%  spectra

as = { 'm1_initiated', 'mutual' };
bs = { 'm2_initiated', 'm1' };
sub_cats = { {'roi', 'region'}, {'roi', 'region'} };
lab_cats = { 'initiator', 'looks_by' };
selectors = { 'mutual', {} };

assert( isequal(numel(as), numel(bs), numel(sub_cats), numel(lab_cats)), numel(selectors) ...
  , 'Subtraction specifiers do not match.' );

subdat = [];
sublabs = fcat();

for i = 1:numel(as)
  shared_utils.general.progress( i, numel(as) );
  
  uselabs = labs';
  usedat = zdat;
  
  mask = fcat.mask( uselabs ...
    , @(x, varargin) bfw.catfindnot_substr(x, 'region', varargin{:}), 'ref' ...
    , @find, {'eyes_nf'} ...
    , @find, selectors{i} ...
    , @findnone, '09272018' ...
  );
  
  a = as{i};
  b = bs{i};
  lab_cat = lab_cats{i};

  opfunc = @minus;
  sfunc = @(x) nanmean(x, 1);

  subspec = sub_cats{i};

  [tmp_subdat, tmp_sublabs, I] = dsp3.summary_binary_op( usedat, uselabs' ...
    , subspec, a, b, opfunc, sfunc, mask );

  setcat( tmp_sublabs, lab_cat, sprintf('%s %s %s', a, func2str(opfunc), b) );
  addsetcat( tmp_sublabs, 'subtraction_type', sprintf('subtraction__%d', i) );
  
  append( sublabs, tmp_sublabs );
  subdat = [ subdat; tmp_subdat ];
end

%%  spectra

is_zscored = true;
do_save = true;
subdir = 'redo';

scats = { 'measure', 'roi' };

pltlabs = sublabs';
pltdat = subdat;
  
t_ind = true( size(t) );
f_ind = freqs <= 100;

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

mask = fcat.mask( pltlabs, mask, @find, 'eyes_nf' );

fcats = { 'measure', 'roi', 'region' };
pcats = { 'region', 'roi', 'looks_by', 'measure', 'initiator' };

fcats = csunion( fcats, 'subtraction_type' );

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

  if ( do_save )
    filename_cats = cshorzcat( fcats, pcats );

    z_component = ternary( is_zscored, 'z', 'nonz' );

    full_plot_p = fullfile( plot_p, subdir, 'spectra', z_component );

    for i = 1:numel(f)
      ind = I2{j}(I{i});

      bfw.req_savefig_subdirs( scats, f(i), full_plot_p, prune(mlabs(ind)), filename_cats, 'spectra__' );
    end
  end
end

%%

bla_ind = find( sublabs, {'accg_bla', 'eyes_nf', 'm1_initiated minus m2_initiated', 'mutual'} );
bla_ind = findnone( sublabs, {'09272018', 'm2'}, bla_ind );

f_ind = freqs >= 4 & freqs <= 13;
band_dat = squeeze( nanmean(subdat(:, f_ind, :), 2) );
mean_dat = squeeze( nanmean(band_dat(bla_ind, :), 1) );

figure(2); clf();
plot( t, mean_dat );

%%  lines

is_zscored = true;
is_per_initiator = true;
is_per_site = false;
match_initiators = false;
do_save = true;
is_smoothed = false;

subdir = 'lines';
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
    dsp3.req_savefig( f(i), fullfile(plot_p, subdir), mlabs(fig_I{i}), plt_spec, prefix );
  end
end