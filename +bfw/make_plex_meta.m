function make_plex_meta(varargin)

defaults = bfw.get_common_make_defaults();

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;
osd = params.output_subdir;

un_p = bfw.gid( fullfile('unified', isd), conf );
plex_meta_p = bfw.gid( fullfile('plex_meta', osd), conf );

meta_map = bfw.get_plex_meta_channel_map( conf );

sessions = meta_map('session');
channels = meta_map('channels');
regions = meta_map('region');

mats = bfw.require_intermediate_mats( params.files, un_p, params.files_containing );

parfor i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats), mfilename );
  
  un_file = shared_utils.io.fload( mats{i} );
  
  if ( ~isfield(un_file, 'm1') )
    bfw.print_fail_warn( mats{i}, 'Unified file is missing an "m1" field.' );
    continue;
  end
  
  un_filename = un_file.m1.unified_filename;
  output_filename = fullfile( plex_meta_p, un_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  session = un_file.m1.mat_directory_name;
  
  session_index = strcmp( sessions, session );
  
  if ( nnz(session_index) == 0 )
    bfw.print_fail_warn( un_filename, 'No plex-meta data was defined.' );
    continue;
  end
  
  try
    plex_meta_file = struct();
    plex_meta_file.unified_filename = un_filename;
    plex_meta_file.params = params;
    plex_meta_file.pl2_fileparts = cshorzcat( un_file.m1.plex_directory, un_file.m1.plex_filename );
    plex_meta_file.pl2_filename = un_file.m1.plex_filename;

    chans = channels(session_index);
    regs = regions(session_index);

    [regs, chans] = linearize_channels_regions( chans, regs );

    plex_meta_file.channels = chans;
    plex_meta_file.regions = regs;

    shared_utils.io.require_dir( plex_meta_p );
    shared_utils.io.psave( output_filename, plex_meta_file, 'plex_meta_file' );
    
  catch err
    bfw.print_fail_warn( un_filename, err.message );
    continue;
  end
end

end

function [channels, regions] = linearize_channels_regions(chans, regs)

total_n = sum( cellfun(@numel, chans) );

channels = zeros( total_n, 1 );
regions = cell( total_n, 1 );

stp = 1;

for i = 1:numel(chans)
  chan = chans{i};
  
  for j = 1:numel(chan)
    channels(stp) = chan(j);
    regions(stp) = regs(i);
    
    stp = stp + 1;
  end
end

end