function build_single_file(cpp_filename, increment_version)

%   BUILD_SINGLE_FILE -- Build and install mex file from single .cpp source file.

if ( nargin < 2 )
  increment_version = true;
end

proj_dir = bfw.util.get_project_folder();
mex_dir = fullfile( proj_dir, 'mex' );
out_dir = fullfile( proj_dir, '+bfw', '+mex' );

[~, filename_sans_ext] = fileparts( cpp_filename );

src_file = fullfile( mex_dir, cpp_filename );
vers_filename_sans_ext = sprintf( '%s_version', filename_sans_ext );
ver_src_file = fullfile( mex_dir, sprintf('%s.cpp', vers_filename_sans_ext) );

if ( isunix() && ~ismac() )
  compiler_spec = 'GCC=''/usr/bin/gcc-4.9'' G++=''/usr/bin/g++-4.9'' ';
  addtl_cxx_flags = 'CXXFLAGS="-std=c++1y -fPIC"';
else
  compiler_spec = '';
  addtl_cxx_flags = '';
end

make_version_file( mex_dir, vers_filename_sans_ext, increment_version );

c_optim_flags = 'COPTIMFLAGS="-O3 -fwrapv -DNDEBUG"';
cpp_optim_flags = 'CXXOPTIMFLAGS="-O3 -fwrapv -DNDEBUG"';

cmd = sprintf( 'mex -v %s %s %s%s "%s" "%s" -outdir "%s"', compiler_spec ...
  , c_optim_flags, cpp_optim_flags, addtl_cxx_flags, src_file, ver_src_file, out_dir );
eval( cmd );


end

function make_version_file(mex_dir, vers_filename_sans_ext, increment_version)

vers_dir = fullfile( mex_dir, 'version' );

if ( exist(vers_dir, 'dir') ~= 7 )
  mkdir( vers_dir );
end

header_filename = sprintf( '%s.hpp', vers_filename_sans_ext );
src_filename = sprintf( '%s.cpp', vers_filename_sans_ext );
raw_filename = sprintf( '%s.txt', vers_filename_sans_ext );

header_file_path = fullfile( mex_dir, header_filename );
src_file_path = fullfile( mex_dir, src_filename ); 
raw_file_path = fullfile( vers_dir, raw_filename );

if ( ~increment_version && shared_utils.io.fexists(raw_file_path) )
  id = fileread( raw_file_path );
else
  id = char( java.util.UUID.randomUUID() );
end

header_file_contents = '#pragma once\n extern const char* const BFW_VERSION_ID;';
src_file_contents = sprintf( '#include "%s"\n const char* const BFW_VERSION_ID = "%s";' ...
  , header_filename, id );
raw_file_contents = id;

write_file( src_file_path, src_file_contents );
write_file( header_file_path, header_file_contents );
write_file( raw_file_path, raw_file_contents );

end

function write_file(file_path, file_contents)

fid = fopen( file_path, 'w+' );
fprintf( fid, file_contents );
fclose( fid );

end