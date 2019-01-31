function make_unified(sub_dirs, varargin)

ff = @fullfile;

defaults = bfw.get_common_make_defaults();
params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;
osd = params.output_subdir;

sub_dirs = shared_utils.cell.ensure_cell( sub_dirs );

unified_output_dir = bfw.gid( ff('unified', osd), conf );
cs_unified_output_dir = bfw.gid( ff('cs_unified', osd), conf );

load_func = @(x) bfw.unify_raw_data( shared_utils.io.fload(x) );

data_root = conf.PATHS.data_root;

base_dir = fullfile( conf.PATHS.data_root, 'raw' );

outerdirs = cellfun( @(x) fullfile(base_dir, x), sub_dirs, 'un', false );

m_dirs = { 'm1', 'm2' };

if ( ispc() )
  dir_sep = '\';
else
  dir_sep = '/';
end

default_session_duration = 400; % s;

for idx = 1:numel(outerdirs)
  fprintf( '\n %d of %d', idx, numel(outerdirs) );
  
  outerdir = outerdirs{idx};
  
  dir_components = strsplit( outerdir, dir_sep );
  
  last_dir = dir_components{end};
  
  all_dir_components = { 'raw', last_dir };
  plex_dir_components = [ all_dir_components, 'plex' ];
  
  data_ = struct();
  
  pl2_dir = fullfile( outerdir, 'plex' );
  plex_directory = fullfile( pl2_dir, 'sorted' );
  plex_dir_components{end+1} = 'sorted';
  
  sorted_dir_exists = shared_utils.io.dexists( plex_directory );
  should_use_sorted = false;
  
  if ( sorted_dir_exists )
    pl2s = shared_utils.io.find( plex_directory, '.pl2' );
    should_use_sorted = ~isempty( pl2s );
  end
  
  if ( ~should_use_sorted )
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
  
  %
  %   get plex sync map
  %
  
  need_provide_plex_sync_index = false;
  got_plex_sync_index = false;
  
  sync_file = 'plex_sync_map.json';

  m_plex_sync_map_file = shared_utils.io.find( pl2_dir, sync_file );
  
  if ( isempty(m_plex_sync_map_file) )
    need_provide_plex_sync_index = true;    
  else
    assert__n_files( m_plex_sync_map_file, 1, sync_file, pl2_dir );
    m_plex_sync_map = get_plex_sync_map( bfw.jsondecode(m_plex_sync_map_file{1}) );
    
    got_plex_sync_index = true;
  end
  
  for i = 1:numel(m_dirs)
    m_str = m_dirs{i};
    m_dir = fullfile( outerdir, m_str );
    
    if ( ~shared_utils.io.dexists(m_dir) )
      warning( 'Directory "%s" does not exist.', m_dir );
      continue;
    end
    
    m_nscontrol_p = fullfile( m_dir, 'nonsocial_control' );
    m_cal_dir = fullfile( m_dir, 'calibration' );
    m_mats = shared_utils.io.find( m_dir, '.mat' );
    m_edfs = shared_utils.io.find( m_dir, '.edf' );
    m_edf_subdirs = repmat( {''}, size(m_edfs) );
    m_edf_map = shared_utils.io.find( m_dir, '.json' );
    
    %
    %   incorporate nonsocial-control mat files
    %
    task_types = repmat( {'free_viewing'}, size(m_mats) );
    
    if ( exist(m_nscontrol_p, 'dir') == 7 )
      nsc_mats = shared_utils.io.find( m_nscontrol_p, '.mat' );
      nsc_edfs = shared_utils.io.find( m_nscontrol_p, '.edf' );
      nsc_task_types = repmat( {'nonsocial_control'}, size(nsc_mats) );
      nsc_edf_subdirs = nsc_task_types;
      
      m_mats = [ m_mats, nsc_mats ];
      task_types = [ task_types, nsc_task_types ];
      m_edfs = [ m_edfs, nsc_edfs ];      
      m_edf_subdirs = [ m_edf_subdirs, nsc_edf_subdirs ];
    end
    
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
    
    m_data = reconcile_task_data( cellfun(load_func, m_mats, 'un', 0) );
    
    if ( i > 1 && numel(m_mats) ~= n_last_mats )
      warning( 'Number of .mat files does not match between m1 and m2.' );
    end
  
    %
    %   add plex sync id
    %
    
    plex_sync_id_file = shared_utils.io.find( pl2_dir, 'plex_sync_id.json' );
    
    plex_sync_id = 'm2';
    
    if ( numel(plex_sync_id_file) ~= 0 )
      plex_sync_id_struct = bfw.jsondecode( plex_sync_id_file{1} );
      plex_sync_id = plex_sync_id_struct.plex_sync_id;
    end
    
    if ( need_provide_plex_sync_index && ~got_plex_sync_index && strcmpi(m_str, plex_sync_id) )
      
      m_plex_sync_map = get_plex_sync_map_from_data( m_data, m_filenames );
      
      got_plex_sync_index = true;
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
      edf_map_ = bfw.jsondecode( m_edf_map{1} );
      pos_fs = fieldnames( edf_map_ );
      for j = 1:numel(pos_fs)
        edf_num = edf_map_.(pos_fs{j});
        edf_map(pos_fs{j}) = [m_edfs{edf_num}, '.edf'];
      end
    else
      if ( numel(m_edfs) ~= numel(m_data) )
        error( ['\nNumber of edfs for %s does not match' ...
          , ' number of .mat files.'], outerdir );
%         for j = 1:numel(m_data)
%           edf_map(m_filenames{j}) = '';
%         end
      else
        edf_nums = get_filenumbers( m_edfs );
        mat_nums = get_filenumbers( m_filenames );
        for j = 1:numel(mat_nums)
          ind = edf_nums == mat_nums(j);
          
          if ( sum(ind) ~= 1 )
            if ( numel(unique(m_edf_subdirs(ind))) == 1 )
              error( 'Mismatch between edf + position numbers.' );
            end
          end
          
          num_ind = find( ind );
          num_ind = num_ind(1);
          
          edf_map( m_filenames{j} ) = [m_edfs{num_ind}, '.edf'];
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
      
    m_screen_rect = shared_utils.io.find( m_cal_dir, '.json' );
    
    if ( numel(m_screen_rect) > 0 )
      scr_rect = bfw.jsondecode( m_screen_rect{1} );
      scr_rect = arrayfun( @(x) scr_rect.screen_rect, 1:numel(m_data), 'un', 0 );
    else
      scr_rect = get_screen_rect( m_data );
    end
    
    %
    %   attach key map file to data, if it's not already attached
    %
    
    if ( ~isfield(m_data, 'far_plane_key_map') )
       m_map_mats = shared_utils.io.find( outerdir, 'calibration_key_map.mat' );
       assert__n_files( m_map_mats, 1, 'calibration key map', outerdir );
       m_key_map = shared_utils.io.fload( m_map_mats{1} );
       for j = 1:numel(m_data)
         m_data(j).far_plane_key_map = m_key_map;
       end
    end
     
    %
    %   attach mountain sort filename to data, if it exists
    %
    
    ms_firings_filemap_file = '';
    ms_firings_channel_map_file = '';
    
    ms_firings_filemap_directory_path = fullfile( outerdir, 'mountain_sort' );

    if ( shared_utils.io.dexists(ms_firings_filemap_directory_path) )
      file_map_full_file = fullfile( ms_firings_filemap_directory_path, 'file_map.json' );
      if ( shared_utils.io.fexists(file_map_full_file) )
        ms_firings_filemap_file = 'file_map.json';
      else 
        fprintf( ['\n Warning: "moutain_sort" directory exists in "%s", but no' ...
          , ' file_map.json file was found within.'], outerdir );
      end
    end
    
    mountain_sort_directory_path = fullfile( data_root, 'mountain_sort' );
    
    if ( shared_utils.io.dexists(mountain_sort_directory_path) )
      ms_firings_channel_map_files = shared_utils.io.dirnames( mountain_sort_directory_path, '.xlsx', false );
      
      ms_firings_channel_map_files = exclude_leading( ms_firings_channel_map_files, {'.', '_', '~'} );
      
      if ( numel(ms_firings_channel_map_files) == 0 )
        fprintf( ['\n Warning: moutain sort directory "%s" exists, but' ...
          , ' no channel map excel file exists.'] );
      else
        assert__n_files( ms_firings_channel_map_files, 1 ...
          , 'mountain sort channel map file', mountain_sort_directory_path );
        ms_firings_channel_map_file = ms_firings_channel_map_files{1};
      end
    end
    
    %
    %   add session duration, if it does not exist
    %
    
    if ( ~isfield(m_data, 'session_duration') )
      for j = 1:numel(m_data)
        m_data(j).session_duration = default_session_duration;
      end
    end
    
    %
    %
    %
    assert( got_plex_sync_index, 'Missing plex sync index map for "%s".', m_dir );
    
    for j = 1:numel(m_data)      
      mat_index = str2double( m_filenames{j}(numel('position_')+1:end) );
      edf_filename = edf_map(m_filenames{j});
      
      current_plex_sync_index = m_plex_sync_map( m_filenames{j} );
      
      m_data(j).plex_sync_id = plex_sync_id;
      m_data(j).plex_directory = plex_dir_components;
      m_data(j).plex_filename = pl2_file;
      m_data(j).plex_region_map_filename = 'regions.json';
      m_data(j).plex_unit_map_filename = 'units.json';
      m_data(j).ms_firings_file_map_filename = ms_firings_filemap_file;
      m_data(j).ms_firings_file_map_directory = [ all_dir_components, 'mountain_sort' ];
      m_data(j).ms_firings_channel_map_filename = ms_firings_channel_map_file;
      m_data(j).ms_firings_directory = { 'mountain_sort' };
      m_data(j).mat_directory = m_dir_components;
      m_data(j).mat_directory_name = last_dir;
      m_data(j).mat_filename = m_filenames{j};
      m_data(j).unified_filename = bfw.make_intermediate_filename( last_dir, m_filenames{j} );
      m_data(j).edf_filename = fullfile( m_edf_subdirs{j}, edf_filename );
      m_data(j).mat_index = mat_index;
      m_data(j).plex_sync_index = current_plex_sync_index;
      m_data(j).screen_rect = scr_rect{j};
      m_data(j).task_type = task_types{j};
    end

    data_.(m_str) = m_data;
    
    n_last_mats = numel( m_mats );

    
    cs_plus_dir = fullfile( m_dir, 'cs_plus' );
    
    if ( shared_utils.io.dexists(cs_plus_dir) )
      csplus_unified( cs_unified_output_dir, m_plex_sync_map, m_data, last_dir, m_str, cs_plus_dir )
    end
  end
  
 
  [max_n_files, max_ind] = max( structfun(@numel, data_) );
  all_fields = fieldnames( data_ );
  max_field = all_fields{max_ind};
  
  for i = 1:max_n_files 
    fprintf( '\n\t Saving %d of %d', i, max_n_files );
    data = struct();
    
    m_filename = data_.(max_field)(i).mat_filename;
    u_filename = bfw.make_intermediate_filename( last_dir, m_filename );
    
    for j = 1:numel(all_fields)
      current_m_field = all_fields{j};
      current_m_data = data_.(current_m_field);
      
      match_ind = arrayfun( @(x) strcmp(x.mat_filename, m_filename), current_m_data );
      n_match = sum( match_ind );
      
      switch ( n_match )
        case 0
          continue;
        case 1
          data.(current_m_field) = current_m_data(match_ind);
          data.(current_m_field).unified_filename = u_filename;
          data.(current_m_field).unified_directory = unified_output_dir;
        otherwise
          error( 'Too many matches.' );
      end
    end
    
    shared_utils.io.require_dir( unified_output_dir );
    file = fullfile( unified_output_dir, u_filename );
    save( file, 'data' );
  end
end

end

function csplus_unified(cs_unified_p, plex_sync_map, m_data, session_dir, m_dir, filep)

mats = shared_utils.io.dirnames( filep, '.mat', false );
edfs = shared_utils.io.dirnames( filep, '.edf', false );

assert( numel(mats) == numel(edfs), 'Number of .mat files must match number of .edf files.' );

un_dat = m_data(1);

mat_filenumbers = get_filenumbers( mats, 'mat' );
edf_filenumbers = get_filenumbers( edfs, 'edf' );

for i = 1:numel(mats)
  data = shared_utils.io.fload( fullfile(filep, mats{i}) );
  
  [~, fname] = fileparts( mats{i} );
  
  unified_filename = bfw.make_intermediate_filename( session_dir, fname );
  
  mat_filenumber = mat_filenumbers(i);
  matching_edf = edf_filenumbers == mat_filenumber;
  
  assert( sum(matching_edf) == 1, 'Expected 1 matching edf file; got %d', sum(matching_edf) );
  
  unified_file = struct();
  
  unified_file.data = data;
  unified_file.cs_unified_filename = unified_filename;
  unified_file.unified_filename = un_dat.unified_filename;
  unified_file.edf_filename = edfs{matching_edf};
  unified_file.mat_filename = fname;
  unified_file.m_id = m_dir;
  unified_file.mat_directory = { 'raw', session_dir, m_dir, 'cs_plus' };
  unified_file.mat_directory_name = session_dir;
  
  unified_file.mat_index = mat_filenumbers(i);
  
  if ( isfield(data.sync, 'sync_index') )
    unified_file.plex_sync_index = data.sync.sync_index + 1;
  else
    unified_file.plex_sync_index = plex_sync_map(fname);
  end
  
  save_p = fullfile( cs_unified_p, m_dir );
  
  shared_utils.io.require_dir( save_p );
  save( fullfile(save_p, unified_filename), 'unified_file' );    
end


end

function m_data = reconcile_task_data(m_data)

fs = cellfun( @fieldnames, m_data, 'un', 0 );
unqs = unique( csvertcat(fs{:}) );

for i = 1:numel(m_data)
  tmp = m_data{i};
  
  missing_fields = unqs( ~isfield(tmp, unqs) );
  
  for j = 1:numel(missing_fields)
    f = missing_fields{j};
    
    tmp.(f) = NaN;
  end
  
  m_data{i} = tmp;
end

% because nonsocial control raw data (e.g. dot_2.mat in ~/09122018/m1/nonsocial
% _control/) did not have the calibration info, I
% directly copy it from other position (e.g. position 1)
calif = {'far_plane_calibration','far_plane_constants','far_plane_key_map','far_plane_padding'};
for i = 1:numel(m_data)
    for i_c = 1:numel(calif)
        if isequaln( m_data{i}.(calif{i_c}), NaN) 
           m_data{i}.(calif{i_c}) = m_data{1}.(calif{i_c});
        end
    end
end    
m_data = m_data(:);
m_data = vertcat( m_data{:} );

end

function files = exclude_leading(files, patterns)

if ( ~iscell(patterns) ), patterns = { patterns }; end

for i = 1:numel(patterns)
  if ( i == 1 )
    ind = cellfun( @(x) shared_utils.char.starts_with(x, patterns{i}), files );
  else
    ind = ind | cellfun( @(x) shared_utils.char.starts_with(x, patterns{i}), files );
  end
end

files = files(~ind);

end

function assert__n_files(files, N, kind, directory)
assert( numel(files) == N, ['Expected to find %d "%s"' ...
    , ' file in "%s", but there were %d.'], N, kind, directory, numel(files) );
end

function nums = get_filenumbers(m_edfs, kind)

if ( nargin < 2 ), kind = 'edf'; end

num_ind = cellfun( @(x) isstrprop(x, 'digit'), m_edfs, 'un', false );
cellfun( @(x) assert(any(x), 'Improper %s file format.', kind), num_ind );
nums = zeros( size(num_ind) );
for j = 1:numel(num_ind)
  nums(j) = str2double( m_edfs{j}(num_ind{j}) );
end

validateattributes( nums, {'double'}, {'real', 'integer'} );

end

function map = get_plex_sync_map(plex_sync_struct)

map = containers.Map();

fields = fieldnames( plex_sync_struct );

for i = 1:numel(fields)
  map(fields{i}) = plex_sync_struct.(fields{i});
end

end

function map = get_plex_sync_map_from_data(data, filenames)

assert( isfield(data, 'plex_sync_index'), 'Missing "plex_sync_index" field.' );
assert( numel(data) == numel(filenames), 'Filenames do not match data.' );

map = containers.Map();

for i = 1:numel(data)
  map(filenames{i}) = data(i).plex_sync_index + 1;  % indices start from 0.
end

end

function s = get_screen_rect(m_data)

base_rect = [ 0, 0, 1024*3, 768 ];

if ( ~isfield(m_data, 'config') )
  warning( 'No screen rect specified; using default' );
  s = arrayfun( @(x) base_rect, 1:numel(m_data), 'un', 0 );
else
  adjust_rect = [ -1024, 0, 1024, 0 ];
  
  s = cell( size(m_data) );
  
  for i = 1:numel(m_data)
    cal_rect = m_data(i).config.CALIBRATION.cal_rect;
    
    s{i} = cal_rect + adjust_rect;
  end
end

end

