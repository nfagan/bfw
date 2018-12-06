function results = make_edf_raw_samples(varargin)

defaults = bfw.get_common_make_defaults();

inputs = 'edf';
output = 'edf_raw_samples';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

results = loop_runner.run( @make_edf_raw_samples_main, params );

end

function samples_file = make_edf_raw_samples_main(files, unified_filename, params)

edf_file = shared_utils.general.get( files, 'edf' );

m_fields = fieldnames( edf_file );
  
samples_file = struct();
samples_file.unified_filename = unified_filename;
  
for i = 1:numel(m_fields)
  m_str = m_fields{i};

  edf = edf_file.(m_str).edf;

  x = edf.Samples.posX;
  y = edf.Samples.posY;
  t = edf.Samples.time;
  ps = edf.Samples.pupilSize;

  samples_file.(m_str).x = x;
  samples_file.(m_str).y = y;
  samples_file.(m_str).t = t;
  samples_file.(m_str).pupil = ps;
end

end