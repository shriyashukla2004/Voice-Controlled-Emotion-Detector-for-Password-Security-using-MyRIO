%% extract_features_speaker.m — creates speaker CSVs
clear; clc; load('config_paths.mat');

targetFs  = 48000;     % AudioMNIST native
nMFCC     = 20;
trainRatio = 0.60; rng(42);

% Collect WAVs and labels (speaker ID = parent folder name)
d = dir(fullfile(AUDIO_MNIST_ROOT, '**', '*.wav'));
if isempty(d)
    error("No WAVs under %s — set AUDIO_MNIST_ROOT in config_paths.m", AUDIO_MNIST_ROOT);
end

files  = strings(numel(d),1);
labels = strings(numel(d),1);
for k = 1:numel(d)
    files(k) = string(fullfile(d(k).folder, d(k).name));
    parts = split(string(d(k).folder), filesep);
    labels(k) = parts(end);     % e.g., "01"
end

% Per-speaker stratified split
u = unique(labels); train=false(numel(files),1); test=false(numel(files),1);
for i=1:numel(u)
    idx = find(labels==u(i)); n = numel(idx);
    if n==1, train(idx)=true; continue; end
    nTest = max(1, round((1-trainRatio)*n)); nTest = min(nTest, n-1);
    idx = idx(randperm(n));
    test(idx(1:nTest)) = true; train(idx(nTest+1:end)) = true;
end
if ~any(test) && numel(files)>1, rp=randperm(numel(files),1); test(rp)=true; train(rp)=false; end

fprintf("TOTAL: Train=%d | Test=%d | Speakers=%d\n", sum(train), sum(test), numel(u));

% Extract features
Ttr = extractFeatureTable(files(train), labels(train), targetFs, nMFCC);
Tte = extractFeatureTable(files(test),  labels(test),  targetFs, nMFCC);

% Save
outDir = fullfile(PROJECT_ROOT,'outputs','features'); if ~isfolder(outDir), mkdir(outDir); end
writetable(Ttr, fullfile(outDir,'features_train_speaker.csv'));
writetable(Tte, fullfile(outDir,'features_test_speaker.csv'));
fprintf("✅ Saved:\n  %s\n  %s\n", ...
    fullfile(outDir,'features_train_speaker.csv'), fullfile(outDir,'features_test_speaker.csv'));
