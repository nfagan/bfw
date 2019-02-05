function bfw_build_m1_m2_align()

proj_dir = bfw.util.get_project_folder();
mex_dir = fullfile( proj_dir, 'mex' );
out_dir = fullfile( proj_dir, '+bfw', '+mex' );

src_file = fullfile( mex_dir, 'm1_m2_align.cpp' );

cmd = sprintf( 'mex -outdir "%s" "%s"', out_dir, src_file );
eval( cmd );

end