conf = bfw.config.load();

coh_mats = bfw.require_intermediate_mats( [], bfw.get_intermediate_directory('at_coherence') );
lfp_p = bfw.get_intermediate_directory( 'event_aligned_lfp' );

plot_p = fullfile( conf.PATHS.data_root, 'plots', 'coherence', datestr(now, 'mmddyy') );

coh = Container();

got_freqs = false;
got_time = false;

for i = 1:numel(coh_mats)
  fprintf( '\n %d of %d', i, numel(coh_mats) );
  
  c_coh = shared_utils.io.fload( coh_mats{i} );
  
  if ( c_coh.is_link ), continue; end;
  
  coh_params = c_coh.params;
  coh_trial_params = c_coh.within_trial_params;
  
  if ( ~got_time )
    lfp = shared_utils.io.fload( fullfile(lfp_p, c_coh.unified_filename) );
    if ( lfp.is_link )
      lfp = shared_utils.io.fload( fullfile(lfp_p, lfp.data_file) );
    end
    start = lfp.params.look_back;
    stop = lfp.params.look_ahead;
    window_size = lfp.params.window_size;
    step_size = coh_trial_params.step_size;
    sample_rate = lfp.params.sample_rate;
    got_time = true;
  end
  
  if ( ~got_freqs )
    frequencies = c_coh.frequencies;
    got_freqs = true;
  end
  
  coh = coh.append( c_coh.coherence );
end

coh = SignalContainer( coh );

coh.frequencies = frequencies;
coh.start = start;
coh.stop = stop;
coh.fs = sample_rate;
coh.window_size = window_size;
coh.step_size = step_size;

%%

specificity = { 'looks_to', 'looks_by', 'region' };

meaned_coh = coh.each1d( specificity, @rowops.nanmean );

%%  plot regular

to_plt = meaned_coh;

[I, C] = to_plt.get_indices( {'looks_by'} );

for i = 1:numel(I)
  
plt = to_plt(I{i});

figure(1); clf();

plt.spectrogram( specificity ...
  , 'shape', [2, 3] ...
  , 'frequencies', [0, 100] ...
  );

kind = 'non_subtracted_coherence';
fnames_are = { 'region', 'looks_to', 'looks_by' };
fname = strjoin( flat_uniques(plt, fnames_are), '_' );
full_plotp = fullfile( plot_p, kind );
full_fname = fullfile( full_plotp, fname );

shared_utils.io.require_dir( full_plotp );
shared_utils.plot.save_fig( gcf(), full_fname, {'epsc', 'png', 'fig'} );

end

%%  plot subtracted

plt = meaned_coh;
% plt = plt({'mutual'}) - plt({'m1'});
% plt = plt.replace( 'mutual_minus_m1', 'mut-excl' );

plt = plt({'mutual', 'm1'});
plt = plt({'eyes'}) - plt({'face'});
plt = plt.replace( 'eyes_minus_face', 'eyes-face' );

figure(1); clf();

plt.spectrogram( specificity ...
  , 'shape', [2, 3] ...
  , 'frequencies', [0, 100] ...
  );

kind = 'subtracted_coherence';
fnames_are = { 'region', 'looks_to', 'looks_by' };
fname = strjoin( flat_uniques(plt, fnames_are), '_' );
full_plotp = fullfile( plot_p, kind );
full_fname = fullfile( full_plotp, fname );

shared_utils.io.require_dir( full_plotp );
shared_utils.plot.save_fig( gcf(), full_fname, {'epsc', 'png', 'fig'} );

