function outs = bfw_get_n_sites(varargin)

defaults = bfw.get_common_make_defaults();
params = bfw.parsestruct( defaults, varargin );

conf = params.config;

aligned_lfp_mats = bfw.rim( params.files, bfw.gid('raw_aligned_lfp', conf) ...
  , params.files_containing );
meta_p = bfw.gid( 'meta', conf );

labels = rowcell( numel(aligned_lfp_mats) );
cats = rowcell( rows(labels) );

parfor i = 1:numel(aligned_lfp_mats)
  shared_utils.general.progress( i, numel(aligned_lfp_mats) );
  
  lfp_file = shared_utils.io.fload( aligned_lfp_mats{i} );
  meta_file = bfw.load_intermediate( meta_p, lfp_file.unified_filename );
  
  c_labs = fcat.from( lfp_file.labels, lfp_file.categories );
  keepeach( c_labs, {'region', 'channel'} );
  
  join( c_labs, bfw.struct2fcat(meta_file) );
  
  labels{i} = c_labs;
  cats{i} = lfp_file.categories(:)';
end

all_cats = unique( cshorzcat(cats{:}) );

cellfun( @(x) addcat(x, all_cats), labels, 'un', 0 );

current_labs = fcat();
for i = 1:numel(labels)
  labs = keepeach( labels{i}', {'region', 'channel'} );
  append( current_labs, labs );
end

%%
sessions = bfw.get_sessions_by_stim_type( [], 'cache', true );
mask = fcat.mask( labs, @findnone, 'ref' ...
  , @find, sessions.no_stim_sessions );

bfw.unify_region_labels( labs );

[clabs, I] = keepeach( labs', {'region', 'channel', 'session'}, mask );
[clabs2, I2] = keepeach( clabs, {'region'} );

cts = cellfun( @numel, I );
cts2 = cellfun( @numel, I2 );


end