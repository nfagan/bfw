function build_single_file(cpp_filename)

%   BUILD_SINGLE_FILE -- Build and install mex file from single .cpp source file.

proj_dir = bfw.util.get_project_folder();
mex_dir = fullfile( proj_dir, 'mex' );
out_dir = fullfile( proj_dir, '+bfw', '+mex' );

src_file = fullfile( mex_dir, cpp_filename );

if ( isunix() && ~ismac() )
  compiler_spec = 'GCC=''/usr/bin/gcc-4.9'' G++=''/usr/bin/g++-4.9'' ';
  addtl_cxx_flags = 'CXXFLAGS="-std=c++1y -fPIC"';
else
  compiler_spec = '';
  addtl_cxx_flags = '';
end

cmd = sprintf( 'mex -v %s%s -outdir "%s" "%s"', compiler_spec ...
  , addtl_cxx_flags, out_dir, src_file );
eval( cmd );


end