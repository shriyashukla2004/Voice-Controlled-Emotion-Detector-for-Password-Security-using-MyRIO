%% test_impostors_for_13.m
clear; clc; load('config_paths.mat');
claimed = "13";

S = dir(fullfile(AUDIO_MNIST_ROOT, '**', "*_*_*.wav"));
S = S(~contains(string({S.name}),'_'+claimed+'_'));   % exclude true 13s

n = 10; ok = 0;
fprintf("Testing impostors against claimed user %s...\n", claimed);
for i = 1:n
    f = fullfile(S(i).folder, S(i).name);
    r = verify_user_minimal(f, claimed);
    ok = ok + double(r.accept);
    fprintf("[%2d/%2d] %-18s -> %s\n", i, n, S(i).name, string(r.accept));
end
fprintf("Impostor ACCEPTS = %d / %d (should be ~0)\n", ok, n);
