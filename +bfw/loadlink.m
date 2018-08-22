function f = loadlink(datadir, name)

f = shared_utils.io.fload( fullfile(bfw.get_intermediate_directory(datadir), name) );

end