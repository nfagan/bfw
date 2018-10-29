function req_savefig_subdirs(scats, f, p, labs, cats, prefix)

subdir = dsp3.fname( labs, scats );
dsp3.req_savefig( f, fullfile(p, subdir), labs, cats, prefix );

end