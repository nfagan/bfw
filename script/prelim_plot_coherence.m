coh_mats = bfw.require_intermediate_mats( [], bfw.get_intermediate_directory('at_coherence') );
lfp_p = bfw.get_intermediate_directory( 'event_aligned_lfp' );

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

%%

plt = meaned_coh;
plt = plt({'mutual'}) - plt({'m1'});

figure(1); clf();

plt.spectrogram( specificity ...
  , 'shape', [2, 3] ...
  , 'frequencies', [15, 100] ...
  );