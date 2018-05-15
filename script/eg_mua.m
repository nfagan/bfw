lfp_p = bfw.get_intermediate_directory( 'lfp' );
spike_file = bfw.load_one_intermediate( 'spikes', '02' );
un_file = spike_file.unified_filename;
lfp_file = shared_utils.io.fload( fullfile(lfp_p, un_file) );
%%

units = spike_file.data;

chan = 43;
unit_ind = arrayfun( @(x) x.channel == chan & x.rating > 0, units );
units = units(unit_ind);

spike_times = { units(:).times };
spike_times = cell2mat( cellfun(@(x) x(:), spike_times, 'un', false)' );
mua_single_unit_spikes = sort( spike_times );

%%

conf = dsp2.config.load();
freqs = conf.SIGNALS.mua_filter_frequencies;
thresh = conf.SIGNALS.mua_std_threshold;

channel_ind = strcmp( lfp_file.key(:, 1), sprintf('FP%d', chan) );

lfp_data = lfp_file.data(channel_ind, :);

cont = Container( lfp_data, 'dummy', 'dummy' );
cont = SignalContainer( cont );
cont.fs = 40e3;
cont = filter( cont, 'cutoffs', freqs );

cont = dsp2.process.spike.get_mua_psth( cont, thresh );

%%

pattern = '%s_face_eyes_mutual_minus_m1.fig';

regs = { 'bla_dmpfc', 'accg_bla', 'bla_ofc' };

files = cellfun( @(x) sprintf(pattern, x), regs, 'un', false );

% files = { 'accg_bla_eyes-face_all__looks_by.fig', 'bla_dmpfc_eyes-face_all__looks_by.fig', 'bla_ofc_eyes-face_all__looks_by.fig' };
% files = { 'accg_bla_eyes-face_all__looks_by.fig', 'bla_dmpfc_eyes-face_all__looks_by.fig', 'bla_ofc_eyes-face_all__looks_by.fig' };
f = FigureEdits( files );

%%
for i = 1:numel(files)
  f = openfig( files{i} );
  shared_utils.plot.save_fig( f, files{i}, {'svg'}, false );  
end