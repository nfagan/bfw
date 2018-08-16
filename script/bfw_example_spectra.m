function bfw_example_spectra()

lfp_dir = bfw.get_intermediate_directory( {'at_raw_power', 'at_coherence'} );
lfp_mats = shared_utils.io.find( lfp_dir, '.mat' );

[data, labs, freqs, t] = bfw.load_signal_measure( lfp_mats );

t_ind = true( size(t) );
f_ind = freqs <= 100;

%%

basemask = find( labs, 'bla_ofc' );

I = findall( labs, 'region', basemask );

selectors = { 'mutual', 'm1', 'eyes', 'face' };

for i = 1:numel(I)
  f = figure(i);
  clf( f );

  mask = find( labs, selectors, I{i} );
  
  if ( isempty(mask) ), continue; end

  pltdat = data(mask, f_ind, t_ind);
  pltlabs = labs(mask);

  pltfreqs = flip( freqs(f_ind) );
  plttime = t(t_ind);

  pl = plotlabeled.make_spectrogram();
  pl.fig = f;

  axs = pl.imagesc( pltdat, pltlabs, {'looks_to', 'looks_by', 'region', 'measure'} );

  shared_utils.plot.fseries_yticks( axs, round(pltfreqs), 5 );
  shared_utils.plot.tseries_xticks( axs, plttime, 5 );
  shared_utils.plot.hold( axs );
  shared_utils.plot.add_vertical_lines( axs, find(plttime == 0) );
end

end