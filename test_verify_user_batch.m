%% test_verify_user_batch.m
% This script tests verify_user() for 10 random audio files of user '13'

clear; clc; close all;
load('config_paths.mat');

S = dir(fullfile(AUDIO_MNIST_ROOT, '**', '*_13*.wav'));
n = min(10, numel(S));   % test up to 10 files
ok = 0;
for i = 1:n
    f = fullfile(S(i).folder, S(i).name);
    r = verify_user(f, '13');
    ok = ok + double(r.accept);
    fprintf("[%2d/%2d] %s -> %s\n", i, n, S(i).name, string(r.accept));
end
fprintf("Accepted %d / %d files for user 13\n", ok, n);
