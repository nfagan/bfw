function build_single_file(cpp_filename, increment_version, varargin)

%   BUILD_SINGLE_FILE -- Build and install mex file from single .cpp source file.
%
%     bfw.mex.build_single_file( src_filename ); builds the mex file given
%     by `src_filename` and makes it accessible via bfw.mex.<src_filename>
%
%     bfw.mex.build_single_file( ..., change_version ); gives a logical
%     scalar `change_version` indicating whether to change the version
%     information for this mex file. Default is false.
%
%     See also mex

defaults = struct();
defaults.gcc_path = '/usr/bin/gcc-4.9';
defaults.gpp_path = '/usr/bin/g++-4.9';

params = parsestruct( defaults, varargin );

if ( nargin < 2 || isempty(increment_version) )
  increment_version = false;
end

proj_dir = bfw.util.get_project_folder();
mex_dir = fullfile( proj_dir, 'mex' );
out_dir = fullfile( proj_dir, '+bfw', '+mex' );

[~, filename_sans_ext] = fileparts( cpp_filename );

src_file = fullfile( mex_dir, cpp_filename );
vers_filename_sans_ext = sprintf( '%s_version', filename_sans_ext );
ver_src_file = fullfile( mex_dir, sprintf('%s.cpp', vers_filename_sans_ext) );

if ( isunix() && ~ismac() )
  compiler_spec = sprintf( 'GCC="%s" G++="%s" ', params.gcc_path, params.gpp_path );
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

use_old_version = ~increment_version && shared_utils.io.fexists( raw_file_path );

if ( use_old_version )
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

function params = parsestruct(params, args)

%   PARSESTRUCT -- Assign variable inputs to struct.
%
%     params = ... parsestruct( S, ARGS ) where ARGS is a cell array of
%     'NAME', VALUE pairs assigns to `VALUE1` to field `NAME1` of struct 
%     `S`, and so on for any additional number of ('name', value) pair 
%     inputs. Each 'name' must be a present fieldname of `S`.
%
%     params = ... parsestruct( S, ARGS ) where ARGS is a cell array of 
%     structs `S1`, `S2`, ... first decomposes those structs into a series 
%     of 'field', value pairs, and assigns the contents to `S` as above.
%
%     params = ... parsestruct( S, ARGS ), where `ARGS` is a cell array of
%     cell arrays `C1`, `C2`, ... recursively flattens those arrays into a 
%     single series of 'field', value pairs, and assigns the contents to 
%     `S` as above.
%
%     Note that `ARGS` can contain any valid combination of struct, cell,
%     or 'name', value paired inputs.
%
%     EX //
%
%     s = struct( 'hello', 10, 'hi', 11 );
%
%     s1 = shared_utils.general.parsestruct( s, {'hello', 11} );
%     s2 = shared_utils.general.parsestruct( s, {struct('hello', 11)} );
%     s3 = shared_utils.general.parsestruct( s, {{'hello', 11}, struct('hi', 11)} );
%
%     IN:
%       - `params` (struct)
%       - `args` (cell)
%     OUT:
%       - `params` (struct)

validateattributes( params, {'struct'}, {'scalar'}, 'parsestruct', 'params' );
validateattributes( args, {'cell'}, {}, 'parsestruct', 'args' );

try 
  args = merge_struct_cell( args );
catch err
  throw( err );
end

N = numel( args );

for i = 1:2:N
  name = args{i};
  
  if ( isfield(params, name) )
    params.(name) = args{i+1};
  else
    error( get_error_str_unrecognized_param(fieldnames(params), name) );
  end
end

end

function str = get_error_str_unrecognized_param(fields, name)

base_text = sprintf( '"%s" is not a recognized parameter name.', name );
field_text = sprintf( ' Options are:\n\n - %s', strjoin(sort(fields), '\n - ') );
str = sprintf( '%s%s', base_text, field_text );

end

function s = merge_struct_cell(args)

N = numel( args );
stp = 1;

s = {};

while ( stp <= N )
  v = args{stp};
  
  if ( ischar(v) )
    assert( stp + 1 <= N, '"name", value pairs are incomplete.' );
    
    s = [ s, args(stp), args(stp+1) ];
    stp = stp + 2;
    
  elseif ( iscell(v) )
    s = [ s, merge_struct_cell(v) ];
    stp = stp + 1;
    
  else
    assert( isstruct(args{stp}), ['Inputs must come in "name", value pairs' ...
      , ', or else be struct.'] );
    
    s = [ s, shared_utils.general.struct2varargin(v) ];
    stp = stp + 1;
  end
end


end