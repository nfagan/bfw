function m = get_raw_aligned_intermediate_dir_map(given_kinds, isd, conf)

m = containers.Map();

for i = 1:numel(given_kinds)
  kind = given_kinds{i};
  
  switch ( kind )
    case 'time'
      mapped_kind = 'edf_raw_samples';
    case 'position'
      mapped_kind = 'edf_raw_samples';
    case 'bounds'
      mapped_kind = 'raw_bounds';
    case 'eye_mmv_fixations'
      mapped_kind = 'raw_eye_mmv_fixations';
    case 'arduino_fixations'
      mapped_kind = 'raw_arduino_fixations';
    otherwise
      error( 'Unrecognized kind "%s".', kind );
  end 
  
  m(kind) = bfw.gid(fullfile(mapped_kind, isd), conf);
end

end