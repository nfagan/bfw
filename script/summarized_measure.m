function y = summarized_measure(x)

meta = bfw.struct2fcat( bfw.load1('meta', x.unified_filename) );
labs = SparseLabels.from_fcat( join(fcat.from(x), meta) );
y = Container( x.data, labs );

end