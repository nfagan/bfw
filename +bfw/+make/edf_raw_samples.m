function samples_file = edf_raw_samples(files)

%   EDF_RAW_SAMPLES -- Create edf_raw_samples file.
%
%     See also bfw.make.help
%
%     IN:
%       - `files` (containers.Map, struct)
%     FILES:
%       - 'edf'
%     OUT:
%       - `samples_file` (struct)

bfw.validatefiles( files, 'edf' );

edf_file = shared_utils.general.get( files, 'edf' );
unified_filename = bfw.try_get_unified_filename( edf_file );

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