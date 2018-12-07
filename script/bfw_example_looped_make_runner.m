% BFW_EXAMPLE_LOOPED_MAKE_RUNNER
%
%   This script demonstrates the use of a LoopedMakeRunner object to create
%   intermediate files. 
%
%   You can use this script as a template in order to manually perform
%   operations on intermediate files, in lieu of a more automatic
%   bfw.make_* function. Some of these operations might include:
%
%   Loading intermediate files from a directory other than the default directory:
%       Setting the `input_directories` property controls where
%       intermediate files are loaded from.
%     
%   Saving intermediate files in a directory other than the default directory:
%       Setting the `output_directories` property controls where output is
%       saved.
%       
%   Creating intermediate files, and retaining the output, but not saving them:
%       Setting the `keep_output` property to true persists the output in a 
%       field of `results`. Setting the `save` property to false avoids
%       saving such output in `output_directory`.
%
%   This example specifically makes 'meta' intermediate files, but can be
%   adapted to create any kind of intermediate file.
%
%   See also bfw.make.help

conf = bfw.config.load();
runner = bfw.get_looped_make_runner();

% attempt to save output in `output_directory`?
runner.save = false;          

% preserve output in `results`?
runner.keep_output = true;

% allow overwriting files in `output_directory`?
runner.overwrite = false;

% uncomment the line below to restrict input files to those containing '09182018'
% runner.filter_files_func = @(x) bfw.files_containing(x, '09182018');

% `unified_directory` gives the absolute path to a directory containing
% valid 'unified' intermediate .mat files. Files will be loaded from this
% directory. Here we just use the default: the 'unified' subfolder of the 
% 'intermediates' directory, given by: 
%   `fullfile(conf.PATHS.data_root, 'intermediates', 'unified')`.
% But this could be any directory containing valid 'unified' intermediate
% files, so long as the folder name is 'unified'.
unified_directory = bfw.get_intermediate_directory( 'unified', conf );

% `meta_directory` gives the absolute path to the desired folder in which
% to save the output of `bfw.make.meta` (if `runner.save` is true).
meta_directory = '~/Desktop/intermediates/meta';

runner.input_directories = unified_directory;
runner.output_directory = meta_directory;

results = runner.run( @bfw.make.meta );