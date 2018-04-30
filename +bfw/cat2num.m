function ns = cat2num(elements, prefix)

ns = cellfun( @(x) str2double(x(numel(prefix)+1:end)), elements );

end