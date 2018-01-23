function make_unified(sub_dirs)

conf = bfw.config.load();

save_dir = fullfile( conf.PATHS.data_root, 'intermediates', 'unified' );
save_filename = 'unified';

do_save = true;

load_func = @(x) bfw.unify_raw_data( shared_utils.io.fload(x) );

base_dir = fullfile( conf.PATHS.data_root, 'raw' );
% sub_dirs = { '011118', '011618' };

outerdirs = cellfun( @(x) fullfile(base_dir, x), sub_dirs, 'un', false );

m_dirs = { 'm1', 'm2' };

if ( ispc() )
  dir_sep = '\';
else
  dir_sep = '/';
end

for idx = 1:numel(outerdirs)
  
  outerdir = outerdirs{idx};
  
  dir_components = strsplit( outerdir, dir_sep );
  
  last_dir = dir_components{end};
  
  all_dir_components = { 'raw', last_dir };
  plex_dir_components = [ all_dir_components, 'plex' ];
  
  data_ = struct();
  
  pl2_dir = fullfile( outerdir, 'plex' );
  plex_directory = fullfile( pl2_dir, 'sorted' );
  pl2s = shared_utils.io.find( plex_directory, '.pl2' );
  plex_dir_components{end+1} = 'sorted';
  
  if ( isempty(pl2s) )
    plex_directory = fullfile( pl2_dir, 'unsorted' );
    pl2s = shared_utils.io.find( plex_directory, '.pl2' );
    plex_dir_components(end) = { 'unsorted' };
  end
  
  if ( numel(pl2s) ~= 1 )
    assert( numel(pl2s) == 0, 'Expected 1 or 0 .pl2 file in %s, but there were %d' ...
      , outerdir, numel(pl2s) );
    pl2_file = '';
  else
    [~, pl2_file, ext] = fileparts( pl2s{1} );
    pl2_file = sprintf('%s%s', pl2_file, ext );
  end

  for i = 1:numel(m_dirs)
    m_str = m_dirs{i};
    m_dir = fullfile( outerdir, m_str );
    m_cal_dir = fullfile( m_dir, 'calibration' );
    m_mats = shared_utils.io.find( m_dir, '.mat' );
    m_edfs = shared_utils.io.find( m_dir, '.edf' );
    m_edf_map = shared_utils.io.find( m_dir, '.json' );
    
    m_dir_components = all_dir_components;
    m_dir_components{end+1} = m_str;
    
    m_filenames = cell( 1, numel(m_mats) );
    for j = 1:numel(m_mats)
      [~, m_filenames{j}] = fileparts( m_mats{j} );
    end
    
    ignore_file = shared_utils.io.find( m_dir, '.pos_ignore' );
    if ( ~isempty(ignore_file) )
      ignore_file = fileread( ignore_file{1} );
      ignore_files = strsplit( ignore_file, '\n' );
      for j = 1:numel(ignore_files)
        ignore_ind = strcmp( m_filenames, ignore_files{j} );
        if ( any(ignore_ind) )
          m_filenames(ignore_ind) = [];
          m_mats(ignore_ind) = [];
        end
      end
    end
    
    m_data = cellfun( load_func, m_mats );
    
    if ( i > 1 )
      assert( numel(m_mats) == n_last_mats, ['Number of .mat files' ...
        , ' must match between m1 and m2.'] );
    end
    
    %
    %   attach edf files to data, if they're not already attached
    %
    
    edf_map = containers.Map();
    
    m_edfs = cellfun( @shared_utils.path.filename, m_edfs, 'un', false );
    
    if ( ~isempty(m_edfs) && ~isfield(m_data, 'edf_file') )
      assert( numel(m_edfs) == numel(m_data), 'Edfs must match mat data.' );
      nums = get_filenumbers( m_edfs );
      [~, I] = sort( nums );
      m_edfs = m_edfs(I);
%       edf_map_ = jsondecode( fileread(m_edf_map{1}) );
      edf_map_ = bfw.jsondecode( m_edf_map{1} );
      pos_fs = fieldnames( edf_map_ );
      for j = 1:numel(pos_fs)
        edf_num = edf_map_.(pos_fs{j});
        edf_map(pos_fs{j}) = [m_edfs{edf_num}, '.edf'];
      end
    else
      if ( numel(m_edfs) ~= numel(m_data) )
        fprintf( ['\n WARNING: Number of edfs for %s does not match' ...
          , ' number of .mat files.'], outerdir );
        for j = 1:numel(m_data)
          edf_map(m_filenames{j}) = '';
        end
      else
        edf_nums = get_filenumbers( m_edfs );
        mat_nums = get_filenumbers( m_filenames );
        for j = 1:numel(mat_nums)
          ind = edf_nums == mat_nums(j);
          assert( sum(ind) == 1, 'Mismatch between edf + position numbers.' );
          edf_map( m_filenames{j} ) = [m_edfs{ind}, '.edf'];
        end
      end
    end
    
    %
    %   attach calibration file to data, if it's not already attached
    %

    m_cal = shared_utils.io.find( m_cal_dir, '.mat' );

    if ( ~isfield(m_data, 'far_plane_calibration') )
      m_roi = shared_utils.io.fload( m_cal{end} );
      for j = 1:numel(m_data)
        m_data(j).far_plane_calibration = m_roi;
      end
    end
    
    for j = 1:numel(m_data)
      mat_index = str2double( m_filenames{j}(numel('position_')+1:end) );
      edf_filename = edf_map(m_filenames{j});
      m_data(j).plex_directory = plex_dir_components;
      m_data(j).plex_filename = pl2_file;
      m_data(j).mat_directory = m_dir_components;
      m_data(j).mat_directory_name = last_dir;
      m_data(j).mat_filename = m_filenames{j};
      m_data(j).mat_index = mat_index;
      m_data(j).edf_filename = edf_filename;
    end

    data_.(m_str) = m_data;
    
    n_last_mats = numel( m_mats );
  end
  
  for i = 1:numel(data_.(m_dirs{1}))
    data = struct();
    m_filename = data_.(m_dirs{1})(i).mat_filename;
    u_filename = bfw.make_intermediate_filename( save_filename, last_dir, m_filename );
    for j = 1:numel(m_dirs)
      data.(m_dirs{j}) = data_.(m_dirs{j})(i);
      data.(m_dirs{j}).unified_filename = u_filename;
      data.(m_dirs{j}).unified_directory = save_dir;
    end
    if ( do_save )
      shared_utils.io.require_dir( save_dir );
      file = fullfile( save_dir, u_filename );
      save( file, 'data' );
    end
  end
end

end

function nums = get_filenumbers( m_edfs, kind )

if ( nargin < 2 ), kind = 'edf'; end

num_ind = cellfun( @(x) isstrprop(x, 'digit'), m_edfs, 'un', false );
cellfun( @(x) assert(any(x), 'Improper %s file format.', kind), num_ind );
nums = zeros( size(num_ind) );
for j = 1:numel(num_ind)
  nums(j) = str2double( m_edfs{j}(num_ind{j}) );
end

end

