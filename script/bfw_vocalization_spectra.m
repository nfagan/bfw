[y, fs] = audioread( '/Users/Nick/Downloads/OFC 02192022 run1-12.m4a' );

%%

rs_factor = 4;  % resample to 1/4 original sampling rate
rs = resample( y, 1, rs_factor );
r_fs = fs / rs_factor;

%%

bin_s = 0.025;
bin_step_s = 0.025;

[S, f, t] = tf_spectrum( rs, r_fs ...
  , 't0', 0 ...
  , 't1', 60 ...
  , 'bin_s', bin_s ...
  , 'bin_step_s', bin_step_s ...
);

%%

pl = plotlabeled.make_spectrogram( f, t );
pl.add_smoothing = true;
% pl.smooth_func = @(x) imgaussfilt(x, 4);
axs = pl.imagesc( S, fcat.create('run', 'run1'), 'run' );
shared_utils.plot.fseries_yticks( axs, flip(round(f)), 10 );
shared_utils.plot.tseries_xticks( axs, round(t*1000)/1e3, 100 );

shared_utils.plot.set_clims( axs, [0, 1e-8] );

%%

function [S, f, t] = tf_spectrum(y, fs, varargin)

defaults = struct();
defaults.bin_s = 1;
defaults.bin_step_s = 1;
defaults.t0 = 0;
defaults.t1 = numel( y ) / fs;

params = shared_utils.general.parsestruct( defaults, varargin );
bin_s = params.bin_s;
bin_step_s = params.bin_step_s;

bin_size_samples = max( 1, floor(fs * bin_s) );
bin_step_samples = max( 1, floor(fs * bin_step_s) );

t0 = max( 1, floor(fs * params.t0) );
t1 = min( numel(y), floor(fs * params.t1) );

[S, f, t] = sliding_window_spectra( y(t0:t1), fs, bin_size_samples, bin_step_samples, false );

end

function [spectra, f, t] = sliding_window_spectra(y, fs, win, step, discard_uneven)

N = numel( y );
start = 1;
first = true;

assign_stp = 1;

spectra = {};
f = [];
t = [];

while ( first || stop <= N )
  stop = min( start + win - 1, N );
  
  ind = start:stop;
  
  if ( isempty(ind) || (discard_uneven && numel(ind) ~= win) )
    break;
  end
  
  subset = y(ind);
  chron_params = struct( 'Fs', fs, 'trialave', 0, 'tapers', [1.5, 2] );
  [S, f] = mtspectrumc( subset(:), chron_params );
  
  spectra{end+1, 1} = S(:)';  
  t(end+1, 1) = mean( ind ) / fs;
  
  start = start + step;
  assign_stp = assign_stp + 1;
  
  first = false;
end

spectra = cat( 3, spectra{:} );

end