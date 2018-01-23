%{
    allcomb.m -- function for obtaining all combinations of labels in
    <fields>. Taken from http://www.mathworks.com/matlabcentral/fileexchange/10064-allcomb-varargin-
    and lightly reformatted
%}

function A = allcomb(fields)

NC = length(fields);
ii = NC:-1:1;

args = fields(1:NC);

% for cell input, we use to indices to get all combinations
ix = cellfun(@(c) 1:numel(c), args,'un',0) ;

% flip using ii if last column is changing fastest
[ix{ii}] = ndgrid(ix{ii});

A = cell(numel(ix{1}),NC); % pre-allocate the output
for k=1:NC,
    A(:,k) = reshape(args{k}(ix{k}),[],1) ;
end
