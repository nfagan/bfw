function bfw_build_m1_m2_align()

proj_dir = bfw.util.get_project_folder();
mex_dir = fullfile( proj_dir, 'mex' );
out_dir = fullfile( proj_dir, '+bfw', '+mex' );

src_file = fullfile( mex_dir, 'm1_m2_align.cpp' );

if ( isunix() && ~ismac() )
  compiler_spec = 'GCC=''/usr/bin/gcc-4.9'' G++=''/usr/bin/g++-4.9'' ';
else
  compiler_spec = '';
end

cmd = sprintf( 'mex -v %s -outdir "%s" "%s"', compiler_spec, out_dir, src_file );
eval( cmd );

end