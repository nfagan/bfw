function make_edfs()

data_p = bfw.get_intermediate_directory( 'unified' );
save_p = bfw.get_intermediate_directory( 'edf' );

mats = shared_utils.io.find( data_p, '.mat' );

base_filename = 'edf';

do_save = true;

copy_fields = { 'unified_filename', 'unified_directory' };

for i = 1:numel(mats)
  
  current = shared_utils.io.fload( mats{i} );
  fields = fieldnames( current );
  first = current.(fields{1});
  
  if ( isempty(first.edf_filename) )
    continue;
  end
  
  edf = struct();
  
  mat_dir = first.mat_directory_name;
  m_filename = first.mat_filename;
  e_filename = bfw.make_intermediate_filename( base_filename, mat_dir, m_filename );
  
  for j = 1:numel(fields)
    m_dir = current.(fields{j}).mat_directory;
    edf_filename = current.(fields{j}).edf_filename;
    edf.(fields{j}).edf = Edf2Mat( fullfile(m_dir, edf_filename) );
    edf.(fields{j}).medf_filename = e_filename;
    edf.(fields{j}).medf_directory = save_p;
  end
  
  for j = 1:numel(copy_fields)
    for k = 1:numel(fields)
      edf.(fields{k}).(copy_fields{j}) = current.(fields{k}).(copy_fields{j});
    end
  end
  
  if ( do_save )
    shared_utils.io.require_dir( save_p );
    save( fullfile(save_p, e_filename), 'edf' );
  end
end

end