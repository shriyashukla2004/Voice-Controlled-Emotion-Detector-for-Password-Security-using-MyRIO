%% test_verify_user.m — corrected
clear; clc; close all;
load('config_paths.mat');

claimed = "13";  % speaker ID you want to test

% Find files whose MIDDLE token is the speaker ID:
% pattern: <digit>_<speaker>_<utt>.wav -> *_13_*.wav
S = dir(fullfile(AUDIO_MNIST_ROOT, '**', "*_" + claimed + "_*.wav"));
assert(~isempty(S), "No files found for speaker %s under %s", claimed, AUDIO_MNIST_ROOT);

n = min(10, numel(S));
ok = 0;
fprintf("Testing speaker verification for User %s...\n", claimed);

for i = 1:n
    f = fullfile(S(i).folder, S(i).name);
    r = verify_user_minimal(f, claimed);
    ok = ok + double(r.accept);
    % Show parsed speaker from filename to be extra sure
    parts = split(S(i).name, '_');   % {"<digit>","<speaker>","<utt>.wav"}
    spkFromName = erase(parts{2}, ".wav");
    fprintf("[%2d/%2d] %-20s (spk=%s) -> %s\n", i, n, S(i).name, spkFromName, string(r.accept));
end

fprintf("\nSummary: Accepted %d / %d files for user %s\n", ok, n, claimed);
