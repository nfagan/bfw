function copy_intermediates(dst_p, subdirs, varargin)

defaults = struct();
defaults.config = bfw.config.load;
defaults.filter_files = @(x) x;
defaults.dry_run = false;
defaults.require_dir = false;
defaults.verbose = true;

params = shared_utils.general.parsestruct( defaults, varargin );
src_p = fullfile( bfw.dataroot(params.config) );
int_p = fullfile( src_p, 'intermediates' );

for i = 1:numel(subdirs)
  subdirs{i} = fullfile( subdirs{i} );
  subdir_p = fullfile( int_p, subdirs{i} );
  files = params.filter_files( shared_utils.io.find(subdir_p, '.mat') );
  
  if ( params.verbose )
    fprintf( '%s (%d of %d)\n', subdirs{i}, i, numel(subdirs) );
  end
  
  for j = 1:numel(files)
    fname = shared_utils.io.filenames( files{j}, true );
    dir_p = fullfile( dst_p, subdirs{i} );
    full_dst_p = fullfile( dir_p, fname );
    
    if ( params.dry_run )
      fprintf( 'cp %s %s\n', files{j}, full_dst_p );
    else
      if ( params.require_dir )
        shared_utils.io.require_dir( dir_p );        
      elseif ( ~shared_utils.io.dexists(dir_p) )
        error( ['Directory "%s" does not exist. Create this directory first' ...
          , ' or rerun with `''require_dir'', true`'], dir_p );
      end
      
      if ( params.verbose )
        fprintf( '\t%s (%d of %d)\n', full_dst_p, j, numel(files) );
      end
      
      copyfile( files{j}, full_dst_p );
    end
  end
end

end