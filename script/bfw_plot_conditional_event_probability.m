p_out = bfw_conditional_event_probability( ...
  'is_parallel', true ...
  , 'bin_width_s', 10 ...
);

%%

labs = p_out.labels';
freqs = p_out.frequencies;
bin_indices = p_out.bin_indices;

mask = fcat.mask( labs ...
  , @find, 'no-stimulation' ...
  , @find, 'free_viewing' ...
  , @find, 'm1' ...
);

is_eyes = find( labs, 'eyes_nf', mask );
is_mouth = find( labs, 'mouth', mask );

assert( numel(is_eyes) == numel(is_mouth), 'N mouth must match N eyes.' );

%%

[mouth_freqs, mouth_labs] = indexpair( freqs, labs', is_mouth );
[eye_freqs, eye_labs] = indexpair( freqs, labs', is_eyes );

is_mouth_bin = mouth_freqs > 0;
is_eye_bin = eye_freqs > 0;

m0_e0 = pnz( ~is_mouth_bin & ~is_eye_bin );
m0_e1 = pnz( ~is_mouth_bin & is_eye_bin );
m1_e1 = pnz( is_mouth_bin & is_eye_bin );
m1_e0 = pnz( is_mouth_bin & ~is_eye_bin );

p_e0_m0 = m0_e0 / (m0_e0 + m0_e1);
p_e1_m0 = m0_e1 / (m0_e0 + m0_e1);

p_e0_m1 = m1_e0 / (m1_e0 + m1_e1);
p_e1_m1 = m1_e1 / (m1_e0 + m1_e1);

dat = [ p_e0_m0; p_e1_m0; p_e1_m1; p_e0_m1 ];
roi_labs = fcat.create( 'roi' ...
  , {'no eyes | no mouth', 'eyes | no mouth', 'eyes | mouth', 'no eyes | mouth'} );

pl = plotlabeled.make_common();
pl.y_lims = [0 1];
pl.fig = figure(2);

pl.bar( dat, roi_labs, 'roi', {}, {} );