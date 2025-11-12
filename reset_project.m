%% reset_project.m — deletes old outputs and clears state (safe)
clear; clc; close all force;

% >>> EDIT your project root once <<<
PROJECT_ROOT = 'C:\Users\admin\Documents\MATLAB';

outDir = fullfile(PROJECT_ROOT,'outputs');
if isfolder(outDir)
    fprintf('Deleting old outputs: %s\n', outDir);
    rmdir(outDir,'s');
end
mkdir(fullfile(outDir,'features'));
mkdir(fullfile(outDir,'models'));
fprintf('✅ Fresh outputs folder created at: %s\n', outDir);
